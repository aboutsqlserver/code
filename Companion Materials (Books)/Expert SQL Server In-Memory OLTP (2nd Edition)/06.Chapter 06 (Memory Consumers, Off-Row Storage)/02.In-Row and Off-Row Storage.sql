/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 06: Memory Consumers and Off-Row Storage            */
/*                      02. In-Row and Off-Row Storage                      */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists dbo.MemoryConsumers;

create table dbo.MemoryConsumers
(
    ID int not null
        constraint PK_MemoryConsumers
        primary key nonclustered hash with (bucket_count=1024),
    Name varchar(256) not null,
    index IDX_Name nonclustered(Name)
)
with (memory_optimized=on, durability=schema_only);

select 
    i.name as [Index], i.index_id, a.xtp_object_id, a.type_desc, a.minor_id
    ,c.memory_consumer_id, c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes, c.used_bytes
from 
    sys.dm_db_xtp_memory_consumers c join
        sys.memory_optimized_tables_internal_attributes a on
            a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
    left outer join sys.indexes i on
            c.object_id = i.object_id and 
            c.index_id = i.index_id and
            a.minor_id = 0 
where
    c.object_id = object_id('dbo.MemoryConsumers');
go

alter table dbo.MemoryConsumers add
    RowOverflowCol varchar(8000),
    LOBCol varchar(max);
go

select 
    i.name as [Index], i.index_id, a.xtp_object_id, a.type_desc, a.minor_id
    ,c.memory_consumer_id, c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes, c.used_bytes
	,'',''
from 
    sys.dm_db_xtp_memory_consumers c join
        sys.memory_optimized_tables_internal_attributes a on
            a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
    left outer join sys.indexes i on
            c.object_id = i.object_id and 
            c.index_id = i.index_id and
            a.minor_id = 0 
where
    c.object_id = object_id('dbo.MemoryConsumers');
go
