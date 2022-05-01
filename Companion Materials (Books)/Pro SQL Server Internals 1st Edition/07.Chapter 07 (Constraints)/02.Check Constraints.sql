/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                        Chapter 07. Constraints                           */
/*                            Check Constraints                             */
/****************************************************************************/

use [SqlServerInternals]
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'CheckConstraintTest'    
)
	drop table dbo.CheckConstraintTest
go

if object_id(N'dbo.DummyCheck','FN') is not null
	drop function dbo.DummyCheck
go

create table dbo.CheckConstraintTest
(
	Value varchar(32) not null
);

/*** No Constraints ***/
set statistics time on

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.CheckConstraintTest(Value)
	select 'ABC'
	from IDs;

set statistics time off
go


/*** Simple  Constraints ***/
truncate table dbo.CheckConstraintTest
go

alter table dbo.CheckConstraintTest
with check
add constraint CHK_CheckConstraintTest_Value
check (Value = 'ABC')
go

set statistics time on

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.CheckConstraintTest(Value)
	select 'ABC'
	from IDs;

set statistics time off
go


/*** Standard Function ***/
truncate table dbo.CheckConstraintTest
go

alter table dbo.CheckConstraintTest
drop constraint CHK_CheckConstraintTest_Value; 

alter table dbo.CheckConstraintTest
with check
add constraint CHK_CheckConstraintTest_Value
check (Right(Value, 1) = 'C')
go

set statistics time on

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.CheckConstraintTest(Value)
	select 'ABC'
	from IDs;

set statistics time off
go

/*** User-defined Function ***/
truncate table dbo.CheckConstraintTest
go

create function dbo.DummyCheck(@Value varchar(32))
returns bit
with schemabinding
as
begin
	return (1)
end
go

alter table dbo.CheckConstraintTest
drop constraint CHK_CheckConstraintTest_Value; 

alter table dbo.CheckConstraintTest
add constraint CHK_CheckConstraintTest_Value
check (dbo.DummyCheck(Value) = 1)
go

set statistics time on

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.CheckConstraintTest(Value)
	select 'ABC'
	from IDs;

set statistics time off
go