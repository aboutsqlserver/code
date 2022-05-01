/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 07: Columnstore Indexes                      */
/*                       03.Large Deleted Rows Table                        */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

delete from dbo.OrderItems
where OrderId % 100 < 98;
go

select row_group_id, state_desc, total_rows, deleted_rows
    ,size_in_bytes, trim_reason_desc
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('dbo.OrderItems')
order by row_group_id
go

-- 5 minutes - just to be sure
waitfor delay '00:05:00.000';
go

-- Data should be moved back to the delta store
select row_group_id, state_desc, total_rows, deleted_rows
    ,size_in_bytes, trim_reason_desc
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('dbo.OrderItems')
order by row_group_id
go