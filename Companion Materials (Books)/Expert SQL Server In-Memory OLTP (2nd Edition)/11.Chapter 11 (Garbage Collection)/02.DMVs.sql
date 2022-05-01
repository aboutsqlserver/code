/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 11: Garbage Collection                       */
/*                 02.DMVs, which were used in the chapter                  */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

select 
	convert(decimal(7,2),memory_allocated_for_table_kb / 1024.)
		as [memory allocated for table]
	,convert(decimal(7,2),memory_used_by_table_kb / 1024.)
		as [memory used by table]
from 
	sys.dm_db_xtp_table_memory_stats
where 
	object_id = object_id(N'dbo.GCDemo');

select
	s.index_id, i.name, s.rows_touched
	,s.rows_expired, s.rows_expired_removed
from 
	sys.dm_db_xtp_index_stats s left join sys.indexes i on
		s.object_id = i.object_id and 
		s.index_id = i.index_id
where 
	s.object_id = object_id(N'dbo.GCDemo');

select 
	sum(total_enqueues) as [total enqueues]
	,sum(total_dequeues) as [total dequeues]
from 
	sys.dm_xtp_gc_queue_stats;

select sweep_scans_started, sweep_rows_touched
	,sweep_rows_expired, sweep_rows_expired_removed
from sys.dm_xtp_gc_stats;
