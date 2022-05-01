/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 01. Data Storage Internals                     */
/*                          SELECT * and I/O                                */
/****************************************************************************/

use [SqlServerInternals]
go


if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Employees') drop table dbo.Employees;
go

create table dbo.Employees
(
	EmployeeId int not null,
	Name varchar(128) not null,
	Picture varbinary(max) null
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N2 as T2) -- 1,024 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.Employees(EmployeeId, Name, Picture)
	select 
		ID, 'Employee ' + convert(varchar(5),ID), 
		convert(varbinary(max),replicate(convert(varchar(max),'a'),120000))
	from Ids;
go

set statistics io, time on

select * from dbo.Employees;
select EmployeeId, Name from dbo.Employees;

set statistics io, time off
go
