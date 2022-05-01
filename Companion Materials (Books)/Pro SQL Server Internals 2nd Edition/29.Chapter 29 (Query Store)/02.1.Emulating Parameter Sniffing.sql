/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                        Chapter 29. Query Store                           */
/*                Emulating Parameter Sniffing (Session 1)                  */
/****************************************************************************/

set noexec off
go

set nocount on
go

if convert(int,
		left(
			convert(nvarchar(128), serverproperty('ProductVersion')),
			charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
		)
	) < 13
begin
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

use SQLServerInternals
go

drop proc if exists dbo.GetAverageSalary;
drop table if exists dbo.Employees;
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

-- Running the SP 10 times and wait for 90 seconds to allow QA to aggregate the data
-- We assume that interval_length_minutes = 1
-- Run the script from the session 2 during delay
declare
	@I int = 0

while @I < 10
begin
	exec dbo.GetAverageSalary @Country='USA';
	waitfor delay '0:00:00.050';
	select @I += 1;
end;

raiserror('Run Session 2 scipt',0,1) with nowait;
waitfor delay '0:01:30.000';

-- Run the script from Session 2 

set @I = 0;

while @I < 10
begin
	exec dbo.GetAverageSalary @Country='USA';
	waitfor delay '0:00:00.050';
	select @I += 1;
end;
go

-- When you look at Regression SSMS report make sure that dates are configured correctly