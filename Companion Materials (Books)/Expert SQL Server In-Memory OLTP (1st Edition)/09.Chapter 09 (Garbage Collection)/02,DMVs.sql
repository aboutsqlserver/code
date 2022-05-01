/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 09: Garbage Collection                       */
/*                 02.DMVs, which were used in the chapter                  */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

/* Next script uses temporary tables to persists results */
select 
	convert(decimal(7,2),memory_allocated_for_table_kb / 1024.)
		as [memory allocated for table]
	,convert(decimal(7,2),memory_used_by_table_kb / 1024.)
		as [memory used by table]
from 
	sys.dm_db_xtp_table_memory_stats
where 
	object_id = object_id(N'dbo.GCDemo');

select rows_touched, rows_expired, rows_expired_removed
from sys.dm_db_xtp_index_stats 
where object_id = object_id(N'dbo.GCDemo');

select 
	sum(total_enqueues) as [total enqueues]
	,sum(total_dequeues) as [total dequeues]
from 
	sys.dm_xtp_gc_queue_stats
