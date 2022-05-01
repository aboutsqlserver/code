/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 26. Plan Caching                         */
/*                              Plan Guides                                 */
/****************************************************************************/

set noexec off
go

use [SqlServerInternals]
go


/****************************************************************************/
/*      This script clear plan cache. Do not run it on production server    */
/****************************************************************************/
if exists(select * from sys.plan_guides where name='object_plan_guide_demo')
	exec sp_control_plan_guide @Operation = 'DROP', @Name = 'object_plan_guide_demo'; 
go

if exists(select * from sys.plan_guides where name='sql_plan_guide_demo')
	exec sp_control_plan_guide @Operation = 'DROP', @Name = 'sql_plan_guide_demo'; 
go

if exists(select * from sys.plan_guides where name='template_plan_guide_demo')
	exec sp_control_plan_guide @Operation = 'DROP', @Name = 'template_plan_guide_demo'; 
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'GetAverageSalary') drop proc dbo.GetAverageSalary;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Employees') drop table dbo.Employees;
go

create table dbo.Employees
(
	ID int not null,
	Number varchar(32) not null,
	Name varchar(100) not null,
	Salary money not null,
	Country varchar(64) not null,

	constraint PK_Employees
	primary key clustered(ID)
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2 ) -- 65,536 rows
,Nums(Num) as (select row_number() over (order by (select null)) from N5)
insert into dbo.Employees(ID, Number, Name, Salary, Country)
	select 
		Num, 
		convert(varchar(5),Num), 
		'USA Employee: ' + convert(varchar(5),Num), 
		40000,
		'USA'
	from Nums;

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,Nums(Num) as (select row_number() over (order by (select null)) from N3)
insert into dbo.Employees(ID, Number, Name, Salary, Country)
	select 
		65536 + Num, 
		convert(varchar(5),65536 + Num), 
		'Canada Employee: ' + convert(varchar(5),Num), 
		40000,
		'Canada'
	from Nums;

create nonclustered index IDX_Employees_Country
on dbo.Employees(Country);
go

create proc dbo.GetAverageSalary @Country varchar(64)
as
	select Avg(Salary) as [Avg Salary]
	from dbo.Employees
	where Country = @Country;
go

/*** Object plan guide ***/
-- Enable "Include Actual Execution Plan"
exec dbo.GetAverageSalary @Country='Canada';
exec dbo.GetAverageSalary @Country='USA';
go

exec sp_create_plan_guide
	@type = N'OBJECT'
	,@name = N'object_plan_guide_demo'
	,@stmt = N'select Avg(Salary) as [Avg Salary]
	from dbo.Employees
	where Country = @Country'
	,@module_or_batch = N'dbo.GetAverageSalary'
	,@params = null
	,@hints = N'OPTION (OPTIMIZE FOR (@Country UNKNOWN))';
go

exec dbo.GetAverageSalary @Country='Canada';
exec dbo.GetAverageSalary @Country='USA';
go


/*** SQL plan guide ***/
exec sp_create_plan_guide
	@type = N'SQL'
	,@name = N'SQL_plan_guide_demo'
	,@stmt = N'select Country, count(*) as [Count]
from dbo.Employees
group by Country'
	,@module_or_batch = NULL
	,@params = null
	,@hints = N'OPTION (MAXDOP 2)'  ;
go

/*** Template plan guide ***/

dbcc freeproccache
go

-- Sample Query: Ad-hoc
select top 1 ID, Number, Name from dbo.Employees where ID = 5;
go

select 
	p.usecounts, p.cacheobjtype, p.objtype, p.size_in_bytes,
	t.[text]
from 
	sys.dm_exec_cached_plans p
		cross apply sys.dm_exec_sql_text(p.plan_handle) t
where 
	t.[text] like '%Employees%'
order by
	p.objtype desc
option (recompile);
go

declare
	@stmt nvarchar(max)
	,@params nvarchar(max)

-- Getting template for the query. Forcing PARAMETERIZATION FORCED
exec sp_get_query_template
	@querytext = 
		N'select top 1 ID, Number, Name from dbo.Employees where ID = 5;'
	,@templatetext = @stmt output
	,@params = @params output;
	
-- Creating plan guide
exec sp_create_plan_guide
	@type = N'TEMPLATE'
	,@name = N'template_plan_guide_demo'
	,@stmt = @stmt
	,@module_or_batch = null
	,@params = @params
	,@hints = N'OPTION (PARAMETERIZATION FORCED)';
go

select top 1 ID, Number, Name from dbo.Employees where ID = 5;
go

select 
	p.usecounts, p.cacheobjtype, p.objtype, p.size_in_bytes,
	t.[text]
from 
	sys.dm_exec_cached_plans p
		cross apply sys.dm_exec_sql_text(p.plan_handle) t
where 
	t.[text] like '%Employees%'
order by
	p.objtype desc
option (recompile);
go


/*** Validating Plan Guides: SQL Server 2008+ */
select 
	pg.plan_guide_id, pg.name, pg.scope_type_desc
	,pg.is_disabled, vpg.message
from sys.plan_guides pg
	outer apply 
	(
		select message
		from sys.fn_validate_plan_guide(pg.plan_guide_id)
	) vpg
go

/*** Cleanup ***/

if exists(select * from sys.plan_guides where name='object_plan_guide_demo')
	exec sp_control_plan_guide @Operation = 'DROP', @Name = 'object_plan_guide_demo' 
go

if exists(select * from sys.plan_guides where name='sql_plan_guide_demo')
	exec sp_control_plan_guide @Operation = 'DROP', @Name = 'sql_plan_guide_demo' 
go

if exists(select * from sys.plan_guides where name='template_plan_guide_demo')
	exec sp_control_plan_guide @Operation = 'DROP', @Name = 'template_plan_guide_demo' 
go
