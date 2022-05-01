/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 06: Memory Consumers and Off-Row Storage            */
/*                          01. Analyzing Varheaps                          */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists dbo.Varheaps
go

create table dbo.Varheaps
(
	Col varchar(8000) not null
		constraint PK_Varheaps 
		primary key nonclustered hash
		with (bucket_count=16384)
)
with (memory_optimized = on, durability = schema_only);
go

select 
    i.name as [Index], i.index_id, c.memory_consumer_id
	,c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes, c.used_bytes
from 
    sys.dm_db_xtp_memory_consumers c 
	    left outer join sys.indexes i on
            c.object_id = i.object_id and c.index_id = i.index_id 
where
    c.object_id = object_id('dbo.Varheaps');
go

insert into dbo.Varheaps(Col) values('a');

select 
    i.name as [Index], i.index_id, c.memory_consumer_id
	,c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes, c.used_bytes
from 
    sys.dm_db_xtp_memory_consumers c 
	    left outer join sys.indexes i on
            c.object_id = i.object_id and c.index_id = i.index_id 
where
    c.object_id = object_id('dbo.Varheaps');
go

insert into dbo.Varheaps(Col) values('b');

select 
    i.name as [Index], i.index_id, c.memory_consumer_id
	,c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes, c.used_bytes
	,'',''
from 
    sys.dm_db_xtp_memory_consumers c 
	    left outer join sys.indexes i on
            c.object_id = i.object_id and c.index_id = i.index_id 
where
    c.object_id = object_id('dbo.Varheaps');
go

insert into dbo.Varheaps(Col) values('ccccc');

select 
    i.name as [Index], i.index_id, c.memory_consumer_id
	,c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes, c.used_bytes
	,'',''
from 
    sys.dm_db_xtp_memory_consumers c 
	    left outer join sys.indexes i on
            c.object_id = i.object_id and c.index_id = i.index_id 
where
    c.object_id = object_id('dbo.Varheaps');
go

declare
	@I int = 2

while @I <= 8000
begin
	insert into dbo.Varheaps(Col) values(replicate('0',@I));
	set @I += 1;
end;

select 
    i.name as [Index], i.index_id, c.memory_consumer_id
	,c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes, c.used_bytes
	,'',''
from 
    sys.dm_db_xtp_memory_consumers c 
	    left outer join sys.indexes i on
            c.object_id = i.object_id and c.index_id = i.index_id 
where
    c.object_id = object_id('dbo.Varheaps');
go

set statistics time on
select count(*) from dbo.HashIndex_HighBucketCount with (index = PK_HashIndex_HighBucketCount) option (maxdop 1);
select count(*) from dbo.HashIndex_HighBucketCount option (maxdop 1);
set statistics time off
go
