/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*             Chapter 04. Special Indexng and Storage Feautes              */
/*                           Calculated Columns                             */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'InputData') drop table dbo.InputData;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'NonPersistedColumn') drop table dbo.NonPersistedColumn;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'PersistedColumn') drop table dbo.PersistedColumn;
if object_id(N'dbo.SameWithID','FN') is not null drop function dbo.SameWithID;
go

create table dbo.InputData
(
	ID int not null
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2 ) -- 65,536 rows
,Nums(Num) as (select row_number() over (order by (select null)) from N5)
insert into dbo.InputData(ID)
	select Num from Nums;
go


create function dbo.SameWithID(@ID int)
returns int
with schemabinding
as
begin
	return @ID;
end
go

create table dbo.NonPersistedColumn
(
	ID int not null,
	NonPersistedColumn as (dbo.SameWithID(ID))
);

create table dbo.PersistedColumn
(
	ID int not null,
	PersistedColumn as (dbo.SameWithID(ID)) persisted
);
go

/* Persisted vs. Non-persisted columns overhead */

set statistics time on

insert into dbo.NonPersistedColumn(ID)
	select ID from dbo.InputData;

insert into dbo.PersistedColumn(ID)
	select ID from dbo.InputData; 

set statistics time off
go

set statistics time on

select count(*)
from dbo.NonPersistedColumn
where NonPersistedColumn = 42;

select count(*)
from dbo.PersistedColumn
where PersistedColumn = 42;

set statistics time off
go


/* Parallel Execution Plans */

-- Enable "Include Actual Execution Plan"
select count(*)
from dbo.NonPersistedColumn
option (querytraceon 8649);

select count(*)
from dbo.PersistedColumn
option (querytraceon 8649); 

select count(*)
from dbo.InputData
option (querytraceon 8649); 
go
