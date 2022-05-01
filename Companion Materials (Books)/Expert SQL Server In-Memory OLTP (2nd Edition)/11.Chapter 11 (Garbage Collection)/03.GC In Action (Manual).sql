/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 11: Garbage Collection                       */
/*                         03.GC In Action (Manual)                         */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

/* This script can be used if you want to monitor GC process manually.
   Restart SQL Server and create the table first */

-- Initial state after insert 
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
from sys.dm_xtp_gc_stats
go

-- DELETING DATA 
declare
	@I int = 1

while @I <= 1500 -- Change to 32768 to see GC activated based on the load
begin
	delete from dbo.GCDemo with (snapshot) where Id = @I
	select @I += 1
end; 

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
from sys.dm_xtp_gc_stats
go

-- SCANNING THE INDEX (add some delay after deletion) 
waitfor delay '00:00:15.000';

select count(*) from dbo.GCDemo with (index = 2)
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
from sys.dm_xtp_gc_stats
go

-- WAITING FOR IDLE THREAD
waitfor delay '00:01:00.000';

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
from sys.dm_xtp_gc_stats
go

-- Depending on your environment it is possible that all work items
-- have been deallocated already. Otherwise, you can trigger 
-- deallocation by the user thread scan

select count(*) from dbo.GCDemo with (index = 2);

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
from sys.dm_xtp_gc_stats
go

-- Garbage collection worker thread statistics
select * 
from sys.dm_db_xtp_gc_cycle_stats;