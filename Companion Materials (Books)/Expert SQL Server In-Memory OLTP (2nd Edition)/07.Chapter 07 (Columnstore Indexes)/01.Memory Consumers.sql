/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 07: Columnstore Indexes                      */
/*                          01.Memory Consumers                             */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists dbo.OrderItems
go

create table dbo.OrderItems
(
	OrderItemId int Identity(1,1) not null
		constraint PK_OrderItems
		primary key nonclustered hash
		with (bucket_count = 4194329) -- 16777316)
	,OrderId int not null
	,ArticleId int not null
	,SalesPrice money not null
	,index CCI_OrderItems clustered columnstore
)
with (memory_optimized = on, durability = schema_and_data);

select index_id, name, type, type_desc, compression_delay 
from sys.indexes 
where object_id = object_id('dbo.OrderItems');

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,N6(C) as (select 0 from N5 as t1 cross join N4 as t2) -- 16,777,316 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N6)
insert into dbo.OrderItems(OrderId, ArticleId, SalesPrice)
	select Id / 3 + 1, Id % 50000, 49.99
	from Ids
	where Id <= 3200000;

-- You should see all new rows in the delta store table heap
select 
    a.xtp_object_id, a.type_desc, a.minor_id
    ,c.memory_consumer_id as [mc Id]
	,c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes / 1024 as [Allocated KB]
    ,c.used_bytes / 1024 as [Used KB]
from 
    sys.dm_db_xtp_memory_consumers c join
        sys.memory_optimized_tables_internal_attributes a on
            a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
where
    c.object_id = object_id('dbo.OrderItems');
go

-- 5 minutes to be sure
waitfor delay '00:05:00.000';
go

-- Data should be compressed at this stage
select 
    a.xtp_object_id, a.type_desc, a.minor_id
    ,c.memory_consumer_id as [mc Id]
	,c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes / 1024 as [Allocated KB]
    ,c.used_bytes / 1024 as [Used KB]
from 
    sys.dm_db_xtp_memory_consumers c join
        sys.memory_optimized_tables_internal_attributes a on
            a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
where
    c.object_id = object_id('dbo.OrderItems');
go

delete from dbo.OrderItems
where OrderItemId % 100 = 0;
go

-- Deleted rows table is populated
select 
    a.xtp_object_id, a.type_desc, a.minor_id
    ,c.memory_consumer_id as [mc Id]
	,c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes / 1024 as [Allocated KB]
    ,c.used_bytes / 1024 as [Used KB]
from 
    sys.dm_db_xtp_memory_consumers c join
        sys.memory_optimized_tables_internal_attributes a on
            a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
where
    c.object_id = object_id('dbo.OrderItems');
go

select row_group_id, state_desc, total_rows, deleted_rows
    ,size_in_bytes, trim_reason_desc
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('dbo.OrderItems')
order by row_group_id


