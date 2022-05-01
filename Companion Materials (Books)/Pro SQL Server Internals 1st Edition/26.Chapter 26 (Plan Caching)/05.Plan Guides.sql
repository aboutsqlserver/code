/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                           Chapter 26. Plan Caching                       */
/*                                Plan Guides                               */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go


/****************************************************************************/
/*      This script clear plan cache. Do not run it on production server    */
/****************************************************************************/
if not exists (select * from sys.tables t where object_id = object_id(N'dbo.Employees')) or
	not exists (select * from sys.procedures p where object_id = object_id(N'dbo.GetAverageSalary')) 
begin
	raiserror('Please create dbo.Employees table and dbo.GetAverageSalary SP from "01.Parameter Sniffing.sql" script',16,1) with nowait
	set noexec on
end
go

if exists(select * from sys.plan_guides where name='object_plan_guide_demo')
	exec sp_control_plan_guide @Operation = 'DROP', @Name = 'object_plan_guide_demo' 
go

if exists(select * from sys.plan_guides where name='sql_plan_guide_demo')
	exec sp_control_plan_guide @Operation = 'DROP', @Name = 'sql_plan_guide_demo' 
go

if exists(select * from sys.plan_guides where name='template_plan_guide_demo')
	exec sp_control_plan_guide @Operation = 'DROP', @Name = 'template_plan_guide_demo' 
go

alter proc dbo.GetAverageSalary @Country varchar(64)
as
begin
	select Avg(Salary) as [Avg Salary]
	from dbo.Employees
	where Country = @Country
end
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
	,@hints = N'OPTION (PARAMETERIZATION FORCED)'
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
