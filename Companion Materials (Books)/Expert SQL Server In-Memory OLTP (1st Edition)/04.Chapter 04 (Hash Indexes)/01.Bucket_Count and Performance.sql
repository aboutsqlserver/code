/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 04: Hash Indexes                           */
/*                   01.Bucket_Count and Performance                        */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'HashIndex_LowBucketCount' and s.name = 'dbo') drop table dbo.HashIndex_LowBucketCount;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'HashIndex_HighBucketCount' and s.name = 'dbo') drop table dbo.HashIndex_HighBucketCount;

create table dbo.HashIndex_LowBucketCount
(
	Id int not null
		constraint PK_HashIndex_LowBucketCount
		primary key nonclustered 
		hash with (bucket_count=1000),
	Value int not null
) 
with (memory_optimized=on, durability=schema_only);

create table dbo.HashIndex_HighBucketCount
(
	Id int not null
		constraint PK_HashIndex_HighBucketCount
		primary key nonclustered 
		hash with (bucket_count=1000000),
	Value int not null
) 
with (memory_optimized=on, durability=schema_only);
go

/* Insert Performance */
set statistics time on
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,N6(C) as (select 0 from N5 as t1 cross join N3 as t2) -- 1,048,576 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N6)
insert into dbo.HashIndex_HighBucketCount(Id, Value)
	select Id, Id
	from ids
	where Id <= 1000000;

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,N6(C) as (select 0 from N5 as t1 cross join N3 as t2) -- 1,048,576 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N6)
insert into dbo.HashIndex_LowBucketCount(Id, Value)
	select Id, Id
	from ids
	where Id <= 1000000;
set statistics time off
go

/* Select Performance */
declare
	@T table(Id int not null primary key)

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N5)
insert into @T(Id)
	select Id from Ids;

set statistics time on
select t.id, c.Cnt
from @T t
		cross apply
		(
			select count(*) as Cnt
			from dbo.HashIndex_HighBucketCount h
			where h.Id = t.Id
		) c;

select t.id, c.Cnt
from @T t
		cross apply
		(
			select count(*) as Cnt
			from dbo.HashIndex_LowBucketCount h
			where h.Id = t.Id
		) c;

set statistics time off;
go

/* Scan Performance */
set statistics time on;

select count(*) from dbo.HashIndex_HighBucketCount;
select count(*) from dbo.HashIndex_LowBucketCount;

set statistics time off;
go