/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    Chapter 05: Nonclustered Indexes                      */
/*                           03.Update Overhead                             */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists dbo.UpdateOverheadDisk;
drop table if exists dbo.UpdateOverheadMemory;
drop table if exists dbo.UpdateOverhead8Idx;
go

create table dbo.UpdateOverheadDisk
(
	Id int not null,
	IndexedCol int not null,
	NonIndexedCol int not null,
	Col3 int not null,
	Col4 int not null,
	Col5 int not null,
	Col6 int not null,
	Col7 int not null,
	Col8 int not null,

	constraint PK_UpdateOverheadDisk
	primary key clustered(Id)
);

create nonclustered index IdX_UpdateOverheadDisk_IndexedCol
on dbo.UpdateOverheadDisk(IndexedCol);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as
 (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N5)
insert into dbo.UpdateOverheadDisk(Id,IndexedCol,NonIndexedCol,Col3
        ,Col4,Col5,Col6,Col7,Col8)
	select Id, Id, Id, Id, Id, Id, Id, Id, Id from Ids;
go

create table dbo.UpdateOverheadMemory
(
	Id int not null
		constraint PK_UpdateOverheadMemory
		primary key nonclustered 
		hash with (bucket_count=2097152),
	IndexedCol int not null,
	NonIndexedCol int not null,
	Col3 int not null,
	Col4 int not null,
	Col5 int not null,
	Col6 int not null,
	Col7 int not null,
	Col8 int not null,

	index IdX_IndexedCol nonclustered(IndexedCol)
) 
with (memory_optimized=on, durability=schema_only);

create table dbo.UpdateOverhead8Idx
(
	Id int not null
		constraint PK_UpdateOverhead8Idx
		primary key nonclustered 
		hash with (bucket_count=2097152),
	IndexedCol int not null,
	NonIndexedCol int not null,
	Col3 int not null,
	Col4 int not null,
	Col5 int not null,
	Col6 int not null,
	Col7 int not null,
	Col8 int not null,

	index IdX_IndexedCol nonclustered(IndexedCol),
	index IdX_Col3 nonclustered(Col3),
	index IdX_Col4 nonclustered(Col4),
	index IdX_Col5 nonclustered(Col5),
	index IdX_Col6 nonclustered(Col6),
	index IdX_Col7 nonclustered(Col7),
	index IdX_Col8 nonclustered(Col8)
) 
with (memory_optimized=on, durability=schema_only);

set statistics time on
insert into dbo.UpdateOverheadMemory(Id,IndexedCol,NonIndexedCol,Col3
        ,Col4,Col5,Col6,Col7,Col8)
	select Id,IndexedCol,NonIndexedCol,Col3,Col4,Col5,Col6,Col7,Col8
	from dbo.UpdateOverheadDisk
option (maxdop 1);

insert into dbo.UpdateOverhead8Idx(Id,IndexedCol,NonIndexedCol,Col3
        ,Col4,Col5,Col6,Col7,Col8)
	select Id,IndexedCol,NonIndexedCol,Col3,Col4,Col5,Col6,Col7,Col8
	from dbo.UpdateOverheadDisk
option (maxdop 1);
set statistics time off
go

set statistics time on
update dbo.UpdateOverheadDisk
set IndexedCol += 1
option (maxdop 1);

update dbo.UpdateOverheadDisk
set NonIndexedCol += 1
option (maxdop 1);
set statistics time off
go

set statistics time on
update dbo.UpdateOverheadMemory
set IndexedCol += 1
option (maxdop 1);

update dbo.UpdateOverheadMemory
set NonIndexedCol += 1
option (maxdop 1);
set statistics time off
go
