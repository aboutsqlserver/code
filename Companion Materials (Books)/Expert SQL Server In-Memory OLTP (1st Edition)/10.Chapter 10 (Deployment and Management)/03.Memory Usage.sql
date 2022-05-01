/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 10: Deployment and Management                    */
/*                      03.Monitoring Memory Usage                          */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
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

select
    mc.object_id
    ,s.name + '.' + t.name as [table]
    ,i.name as [index]
    ,mc.memory_consumer_type_desc
    ,mc.memory_consumer_desc
    ,convert(decimal(9,3),mc.allocated_bytes / 1024. / 1024.)
        as [allocated (MB)]
    ,convert(decimal(9,3),mc.used_bytes / 1024. / 1024.)
        as [used (MB)]
    ,mc.allocation_count
from 
    sys.dm_db_xtp_memory_consumers mc
       left outer join sys.tables t on 
           mc.object_id = t.object_id
       left outer join sys.indexes i on
           mc.object_id = i.object_id and
           mc.index_id = i.index_id
       left outer join sys.schemas s on 
           t.schema_id = s.schema_id
where -- Greater than 1MB
	mc.allocated_bytes > 1048576
order by
    [allocated (MB)] desc
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
