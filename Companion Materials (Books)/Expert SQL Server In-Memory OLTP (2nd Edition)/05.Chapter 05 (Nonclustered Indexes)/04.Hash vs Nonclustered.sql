/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    Chapter 05: Nonclustered Indexes                      */
/*                    04.Hash vs. Nonclustered Indexes                      */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go


drop table if exists dbo.Hash_131072;
drop table if exists dbo.Hash_16384;
drop table if exists dbo.Hash_1024;
drop table if exists dbo.NonClusteredIdx;
go

create table dbo.Hash_131072
(
	Id int not null
	constraint PK_Hash_131072
		primary key nonclustered 
		hash with (bucket_count=131072),
	Value int not null,

	index IDX_Value hash(Value)
	with (bucket_count=131072)
) 
with (memory_optimized=on, durability=schema_only);

create table dbo.Hash_16384
(
	Id int not null
		constraint PK_Hash_16384
		primary key nonclustered 
		hash with (bucket_count=16384),
	Value int not null,

	index IDX_Value hash(Value)
	with (bucket_count=16384)
) 
with (memory_optimized=on, durability=schema_only);

create table dbo.Hash_1024
(
	Id int not null
		constraint PK_Hash_1014
		primary key nonclustered 
		hash with (bucket_count=1024),
	Value int not null,
	
	index IDX_Value hash(Value)
	with (bucket_count=1024)
) 
with (memory_optimized=on, durability=schema_only);

create table dbo.NonClusteredIdx
(
	Id int not null
		constraint PK_NonClusteredIdx
		primary key nonclustered 
		hash with (bucket_count=131072),
	Value int not null,

	index IDX_Value nonclustered(Value)
) 
with (memory_optimized=on, durability=schema_only);
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,N6(C) as (select 0 from N5 as t1 cross join N1 as t2) -- 131,072 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N6)
insert into dbo.Hash_131072(Id,Value)
	select Id, Id
	from Ids
	where Id <= 75000;

insert into dbo.Hash_16384(Id,Value)
	select Id, Value 
	from dbo.Hash_131072;

insert into dbo.Hash_1024(Id,Value)
	select Id, Value 
	from dbo.Hash_131072;

insert into dbo.NonClusteredIdx(Id,Value)
	select Id, Value 
	from dbo.Hash_131072;
go

declare
	@T table(Value int not null primary key)

insert into @T(Value)
	select Id from dbo.Hash_131072;

set statistics time on

select count(*)
from @T t
	cross apply
	(
		select count(*) as Cnt
		from dbo.Hash_131072 h
		where h.Value = t.Value
	) c
where c.Cnt > 0;

select count(*)
from @T t
	cross apply
	(
		select count(*) as Cnt
		from dbo.Hash_16384 h
		where h.Value = t.Value
	) c
where c.Cnt > 0;

select count(*)
from @T t
	cross apply
	(
		select count(*) as Cnt
		from dbo.Hash_1024 h
		where h.Value = t.Value
	) c
where c.Cnt > 0;

select count(*)
from @T t
	cross apply
	(
		select count(*) as Cnt
		from dbo.NonClusteredIdx h
		where h.Value = t.Value
	) c
where c.Cnt > 0;

set statistics time off
go
