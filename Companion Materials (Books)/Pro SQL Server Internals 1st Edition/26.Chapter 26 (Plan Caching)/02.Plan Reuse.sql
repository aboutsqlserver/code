/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                           Chapter 26. Plan Caching                       */
/*                                 Plan Reuse                               */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

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
		p.name = 'SearchEmployee' and s.name = 'dbo' 
)
	drop proc dbo.SearchEmployee
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
go

create proc dbo.SearchEmployee
(
	@Number varchar(32) = null
	,@Name varchar(100) = null
)
as
begin
	select Id, Number, Name, Salary, Country
	from dbo.Employees
	where 
		((@Number is null) or (Number=@Number)) and
		((@Name is null) or (Name=@Name))
end
go

create unique nonclustered index IDX_Employees_Number
on dbo.Employees(Number);

create nonclustered index IDX_Employees_Name
on dbo.Employees(Name);
go

-- Enable "Include Actual Execution Plan"

set statistics io on

exec dbo.SearchEmployee @Number = '10000';
exec dbo.SearchEmployee @Name = 'Canada Employee: 1';
exec dbo.SearchEmployee @Number = '10000', @Name = 'Canada Employee: 1';
exec dbo.SearchEmployee @Number = NULL, @Name = NULL;

set statistics io off
go



-- Solution 1: Statement-level recompile
alter proc dbo.SearchEmployee
(
	@Number varchar(32) = null
	,@Name varchar(100) = null
)
as
begin
	select Id, Number, Name, Salary, Country
	from dbo.Employees
	where 
		((@Number is null) or (Number=@Number)) and
		((@Name is null) or (Name=@Name))
	option (recompile)
end
go

set statistics io on

exec dbo.SearchEmployee @Number = '10000';
exec dbo.SearchEmployee @Name = 'Canada Employee: 1';
exec dbo.SearchEmployee @Number = '10000', @Name = 'Canada Employee: 1';
exec dbo.SearchEmployee @Number = NULL, @Name = NULL;

set statistics io off
go


-- Solution 2: Covering possible combinations of parameters
alter proc dbo.SearchEmployee
(
	@Number varchar(32) = null
	,@Name varchar(100) = null
)
as
begin
	if @Number is null and @Name is null
		select Id, Number, Name, Salary, Country
		from dbo.Employees
	else if @Number is not null and @Name is null
		select Id, Number, Name, Salary, Country
		from dbo.Employees
		where Number=@Number
	else if @Number is null and @Name is not null
		select Id, Number, Name, Salary, Country
		from dbo.Employees
		where Name=@Name
	else 
		select Id, Number, Name, Salary, Country
		from dbo.Employees
		where Number=@Number and Name=@Name
end
go

exec dbo.SearchEmployee @Number = '10000';
exec dbo.SearchEmployee @Name = 'Canada Employee: 1';
exec dbo.SearchEmployee @Number = '10000', @Name = 'Canada Employee: 1';
exec dbo.SearchEmployee @Number = NULL, @Name = NULL;
go


-- Solution 3: Dynamic SQL
alter proc dbo.SearchEmployee
(
	@Number varchar(32) = null
	,@Name varchar(100) = null
)
as
begin
	declare
		@SQL nvarchar(max) 
	
	select @SQL = N'	
select Id, Number, Name, Salary, Country
from dbo.Employees
where 1=1'
	
	if @Number is not null
		select @Sql = @SQL + N' and Number=@Number'
	if @Name is not null
		select @Sql = @SQL + N' and Name=@Name'
	exec sp_executesql @Sql, N'@Number varchar(32), @Name varchar(100)'
		,@Number=@Number, @Name=@Name
end
go

exec dbo.SearchEmployee @Number = '10000';
exec dbo.SearchEmployee @Name = 'Canada Employee: 1';
exec dbo.SearchEmployee @Number = '10000', @Name = 'Canada Employee: 1';
exec dbo.SearchEmployee @Number = NULL, @Name = NULL;
go
