/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 12: Deployment and Management                    */
/*                      03.Monitoring Memory Usage                          */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go


select
    ms.object_id
    ,s.name + '.' + t.name as [table]
    ,ms.memory_allocated_for_table_kb
    ,ms.memory_used_by_table_kb
    ,ms.memory_allocated_for_indexes_kb
    ,ms.memory_used_by_indexes_kb
from 
    sys.dm_db_xtp_table_memory_stats ms
       left outer join sys.tables t on 
           ms.object_id = t.object_id
       left outer join sys.schemas s on 
           t.schema_id = s.schema_id
order by
    ms.memory_allocated_for_table_kb desc
go

;with MemConsumers(object_id, xtp_object_id, alloc_mb, used_mb, allocs)
as
(
	select 
		mc.object_id, mc.xtp_object_id
	    ,convert(decimal(9,3),sum(mc.allocated_bytes) / 1024. / 1024.)
		    as [allocated (MB)]
		,convert(decimal(9,3),sum(mc.used_bytes) / 1024. / 1024.)
		    as [used (MB)]
		,sum(mc.allocation_count) as [allocs]
	from
		sys.dm_db_xtp_memory_consumers mc 
	group by
		mc.object_id, mc.xtp_object_id
)
select 
	mc.object_id, mc.xtp_object_id
    ,a.minor_id, a.type_desc 
	,s.name + '.' + t.name  + 
		iif(a.minor_id = 0,'','.' + col.Name)
			as [Table/Column]
	,mc.allocs as [Allocations]
	,mc.alloc_mb as [Allocated (MB)]
	,mc.used_mb as [Used (MB)]
from 
	MemConsumers mc 
		join sys.memory_optimized_tables_internal_attributes a on
			a.object_id = mc.object_id and 
			a.xtp_object_id = mc.xtp_object_id
		left outer join sys.columns col on
			a.object_id = col.object_id and
			a.minor_id > 0 and 
			a.minor_id = col.column_id
		left outer join sys.tables t on 
			a.object_id = t.object_id
		left outer join sys.schemas s on 
			s.schema_id = t.schema_id
order by
    [Allocated (MB)] desc
go

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
    c.object_id = object_id('Delivery.Orders');
go


select
    memory_consumer_type_desc
    ,memory_consumer_desc
    ,convert(decimal(9,3),allocated_bytes / 1024. / 1024.)
        as [allocated (MB)]
    ,convert(decimal(9,3),used_bytes / 1024. / 1024.)
        as [used (MB)]
    ,allocation_count
from 
   sys.dm_xtp_system_memory_consumers
order by
    [allocated (MB)] desc
go
