/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 07: Columnstore Indexes                      */
/*                        04.Data Management Views                          */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

select row_group_id, state_desc, total_rows, deleted_rows
    ,size_in_bytes, trim_reason_desc
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('dbo.OrderItems')
order by row_group_id;

select *
from sys.column_store_row_groups
where object_id = object_id('dbo.OrderItems')
order by row_group_id;
 
select 
    s.segment_id, s.column_id - 1 as [column_id], c.name as [column]
    ,s.version, s.encoding_type, s.row_count, s.has_nulls, s.magnitude
    ,s.primary_dictionary_id, s.secondary_dictionary_id, s.min_data_id
    ,s.max_data_id, s.null_value
    ,convert(decimal(12,3),s.on_disk_size / 1024.0 / 1024.0)  as [Size MB]
from 
    sys.column_store_segments s join sys.partitions p on
        p.partition_id = s.partition_id
    join sys.indexes i on
        p.object_id = i.object_id
    left join sys.index_columns ic on
        i.index_id = ic.index_id and
        i.object_id = ic.object_id and
        s.column_id - 1 = ic.index_column_id
     left join sys.columns c on
        ic.column_id = c.column_id and
        ic.object_id = c.object_id
where 
    i.name = 'CCI_OrderItems'
order by 
    s.segment_id, s.column_id;

select 
    d.dictionary_id, d.column_id - 1 as [column_id], c.name as [column]
    ,d.version, d.type, d.last_id, d.entry_count
    ,convert(decimal(12,3),d.on_disk_size / 1024.0 / 1024.0)  as [Size MB]
from 
    sys.column_store_dictionaries d join sys.partitions p on
        p.partition_id = d.partition_id
    join sys.indexes i on
        p.object_id = i.object_id
    left join sys.index_columns ic on
        i.index_id = ic.index_id and    
        i.object_id = ic.object_id and
        d.column_id - 1 = ic.index_column_id
    left join sys.columns c on
        ic.column_id = c.column_id and
        ic.object_id = c.object_id
where 
    i.name = 'CCI_OrderItems'
order by 
    d.dictionary_id
