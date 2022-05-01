/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                           Chapter 26. Plan Caching                       */
/*                             Parameter Sniffing                           */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*      This script clear plan cache. Do not run it on production server    */
/****************************************************************************/

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Employees'    
)
	drop table dbo.Employees
go

if exists(
	select * 
	from sys.procedures p join sys.schemas s on 
		p.schema_id = s.schema_id
	where 
		p.name = 'GetAverageSalary' and s.name = 'dbo' 
)
	drop proc dbo.GetAverageSalary
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
begin
	select Avg(Salary) as [Avg Salary]
	from dbo.Employees
	where Country = @Country
end
go

-- Enable "Include Actual Execution Plan"

-- Normal situation
set statistics io on

exec dbo.GetAverageSalary @Country='USA';
exec dbo.GetAverageSalary @Country='Canada';

set statistics io off
go



-- Parameter Sniffing issue
dbcc freeproccache
go

set statistics io on

exec dbo.GetAverageSalary @Country='Canada';
exec dbo.GetAverageSalary @Country='USA';

set statistics io off
go



-- Solution 1: Statement-Level Recompile
alter proc dbo.GetAverageSalary @Country varchar(64)
as
begin
	select Avg(Salary) as [Avg Salary]
	from dbo.Employees
	where Country = @Country
	option (recompile)
end
go

exec dbo.GetAverageSalary @Country='Canada';
exec dbo.GetAverageSalary @Country='USA';
go

-- Solution 2: OPTIMIZE FOR hint
alter proc dbo.GetAverageSalary @Country varchar(64)
as
begin
	select Avg(Salary) as [Avg Salary]
	from dbo.Employees
	where Country = @Country
	option (optimize for(@Country='USA'))
end
go

exec dbo.GetAverageSalary @Country='Canada';
exec dbo.GetAverageSalary @Country='USA';
go

-- Potential issue: Data distribution change
update dbo.Employees set Country='Germany' where Country='USA';

exec dbo.GetAverageSalary @Country='Germany';
go

-- Solution 2: OPTIMIZE FOR UNKNOWN hint
-- SQL SERVER 2008 +
alter proc dbo.GetAverageSalary @Country varchar(64)
as
begin
	select Avg(Salary) as [Avg Salary]
	from dbo.Employees
	where Country = @Country
	option (optimize for(@Country UNKNOWN))
end
go

exec dbo.GetAverageSalary @Country='Canada';
go


-- Solution 4: Use local variables (same effect as OPTIMIZE FOR UNKNOWN hint)
alter proc dbo.GetAverageSalary @Country varchar(64)
as
begin
	declare
		@CountryTmp varchar(64)
	set @CountryTmp = @Country

	select Avg(Salary) as [Avg Salary]
	from dbo.Employees
	where Country = @CountryTmp
end
go

