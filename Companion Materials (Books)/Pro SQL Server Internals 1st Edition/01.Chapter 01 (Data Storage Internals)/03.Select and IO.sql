/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                   Chapter 01. Data Storage Internals                     */
/*                          SELECT * and I/O                                */
/****************************************************************************/

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

create table dbo.Employees
(
	EmployeeId int not null,
	Name varchar(128) not null,
	Picture varbinary(max) null
);

;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 rows
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N2 AS T2) -- 1,024 rows
,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)
insert into dbo.Employees(EmployeeId, Name, Picture)
	select 
		ID, 'Employee ' + convert(varchar(5),ID), 
		convert(varbinary(max),replicate(convert(varchar(max),'a'),120000))
	from Ids
go

set statistics io, time on

select * from dbo.Employees;
select EmployeeId, Name from dbo.Employees;

set statistics io, time off
go
