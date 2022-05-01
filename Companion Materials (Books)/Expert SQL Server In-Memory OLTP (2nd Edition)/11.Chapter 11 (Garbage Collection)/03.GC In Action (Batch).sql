/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 11: Garbage Collection                       */
/*                         04.GC In Action (Batch)                          */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists #MemStats;
drop table if exists #IdxStats;
drop table if exists #GCStats;
drop table if exists #GCSweepStats;


create table #MemStats
(
	ActionId int not null Identity(1,1),
	Action varchar(32) not null,
	TblAllocatedMemory int not null,
	TblUsedMemory int not null
);

-- We are not logging table heap statistics
create table #IdxStats
(
	ActionId int not null Identity(1,1),
	Action varchar(32) not null,
	RowsTouched int not null,
	RowsExpired int not null,
	RowsExpiredRemoved int not null,
);

create table #GCStats
(
	ActionId int not null Identity(1,1),
	Action varchar(32) not null,
	TotalEnqueues int not null,
	TotalDequeues int not null,
);

create table #GCSweepStats
(
	ActionId int not null Identity(1,1),
	Action varchar(32) not null,
	SweepRowsExpired int not null, 
	SweepRowsExpiredRemoved int not null
)
go

insert into #MemStats(Action,TblAllocatedMemory,TblUsedMemory)
	select 
		'Initial', memory_allocated_for_table_kb
		,memory_used_by_table_kb
	from 
		sys.dm_db_xtp_table_memory_stats
	where 
		object_id = OBJECT_ID(N'dbo.GCDemo');

insert into #IdxStats(Action,RowsTouched,RowsExpired,RowsExpiredRemoved)
	select 'Initial', rows_touched, rows_expired, rows_expired_removed
	from sys.dm_db_xtp_index_stats 
	where object_id = OBJECT_ID(N'dbo.GCDemo') and index_id = 2;

insert into #GCStats(Action,TotalEnqueues,TotalDequeues)
	select 'Initial', sum(total_enqueues), sum(total_dequeues)
	from sys.dm_xtp_gc_queue_stats;

insert into #GCSweepStats(Action,SweepRowsExpired,SweepRowsExpiredRemoved)
	select 'Initial', sweep_rows_expired, sweep_rows_expired_removed
	from sys.dm_xtp_gc_stats
go

declare
	@I int = 1

while @I <= 1500 -- Change to 32768 to see GC activated based on the load
begin
	delete from dbo.GCDemo with (snapshot) where Id = @I;
	select @I += 1
end; 

insert into #MemStats(Action,TblAllocatedMemory,TblUsedMemory)
	select 
		'After Deletion', memory_allocated_for_table_kb
		,memory_used_by_table_kb
	from 
		sys.dm_db_xtp_table_memory_stats
	where 
		object_id = OBJECT_ID(N'dbo.GCDemo');

insert into #IdxStats(Action,RowsTouched,RowsExpired,RowsExpiredRemoved)
	select 'After Deletion', rows_touched, rows_expired, rows_expired_removed
	from sys.dm_db_xtp_index_stats 
	where object_id = OBJECT_ID(N'dbo.GCDemo');

insert into #GCStats(Action,TotalEnqueues,TotalDequeues)
	select 'After Deletion', sum(total_enqueues), sum(total_dequeues)
	from sys.dm_xtp_gc_queue_stats;
	
insert into #GCSweepStats(Action,SweepRowsExpired,SweepRowsExpiredRemoved)
	select 'After Deletion', sweep_rows_expired, sweep_rows_expired_removed
	from sys.dm_xtp_gc_stats;	 
go

-- adjust the time if you see Idle worker thread activity
waitfor delay '00:00:10.000'; 
select count(*) from dbo.GCDemo with (index = 2);

insert into #MemStats(Action,TblAllocatedMemory,TblUsedMemory)
	select 
		'After Scan', memory_allocated_for_table_kb
		,memory_used_by_table_kb
	from 
		sys.dm_db_xtp_table_memory_stats
	where 
		object_id = OBJECT_ID(N'dbo.GCDemo');

insert into #IdxStats(Action,RowsTouched,RowsExpired,RowsExpiredRemoved)
	select 'After Scan', rows_touched, rows_expired, rows_expired_removed
	from sys.dm_db_xtp_index_stats 
	where object_id = OBJECT_ID(N'dbo.GCDemo');

insert into #GCStats(Action,TotalEnqueues,TotalDequeues)
	select 'After Scan', sum(total_enqueues), sum(total_dequeues)
	from sys.dm_xtp_gc_queue_stats;
	
insert into #GCSweepStats(Action,SweepRowsExpired,SweepRowsExpiredRemoved)
	select 'After Scan', sweep_rows_expired, sweep_rows_expired_removed
	from sys.dm_xtp_gc_stats;		 
go

waitfor delay '00:01:05.000';

insert into #MemStats(Action,TblAllocatedMemory,TblUsedMemory)
	select 
		'After Delay', memory_allocated_for_table_kb
		,memory_used_by_table_kb
	from 
		sys.dm_db_xtp_table_memory_stats
	where 
		object_id = OBJECT_ID(N'dbo.GCDemo');

insert into #IdxStats(Action,RowsTouched,RowsExpired,RowsExpiredRemoved)
	select 'After Delay', rows_touched, rows_expired, rows_expired_removed
	from sys.dm_db_xtp_index_stats 
	where object_id = OBJECT_ID(N'dbo.GCDemo');

insert into #GCStats(Action,TotalEnqueues,TotalDequeues)
	select 'After Delay', sum(total_enqueues), sum(total_dequeues)
	from sys.dm_xtp_gc_queue_stats;

insert into #GCSweepStats(Action,SweepRowsExpired,SweepRowsExpiredRemoved)
	select 'After Delay', sweep_rows_expired, sweep_rows_expired_removed
	from sys.dm_xtp_gc_stats;		 
go

-- At this point the items may be already deallocated
select count(*) from dbo.GCDemo with (index = 2);
go

insert into #MemStats(Action,TblAllocatedMemory,TblUsedMemory)
	select 
		'After Second Scan', memory_allocated_for_table_kb
		,memory_used_by_table_kb
	from 
		sys.dm_db_xtp_table_memory_stats
	where 
		object_id = OBJECT_ID(N'dbo.GCDemo');

insert into #IdxStats(Action,RowsTouched,RowsExpired,RowsExpiredRemoved)
	select 'After Second Scan', rows_touched, rows_expired, rows_expired_removed
	from sys.dm_db_xtp_index_stats 
	where object_id = OBJECT_ID(N'dbo.GCDemo');

insert into #GCStats(Action,TotalEnqueues,TotalDequeues)
	select 'After Second Scan', sum(total_enqueues), sum(total_dequeues)
	from sys.dm_xtp_gc_queue_stats;

insert into #GCSweepStats(Action,SweepRowsExpired,SweepRowsExpiredRemoved)
	select 'After Second Scan', sweep_rows_expired, sweep_rows_expired_removed
	from sys.dm_xtp_gc_stats;		 
go


select 
	m.Action as Stage
    ,convert(decimal(7,2), m.TblAllocatedMemory / 1024.)
		as [Alloc Memory]
    ,convert(decimal(7,2),m.TblUsedMemory / 1024.)
		as [Used Memory]
	,rowstouched as [Touched]
	,rowsexpired as [Expired]
	,rowsexpiredremoved as [Removed]
	,totalenqueues as [Enqueues]
    ,totaldequeues as [Dequeues]
	,SweepRowsExpired as [Sweep Rows Expired]
	,SweepRowsExpiredRemoved as [Sweep Rows Removed]
from 
    #MemStats m join #IdxStats i on
		m.ActionId = i.ActionId
	join #GCStats g on 
		m.ActionId = g.ActionId
	join #GCSweepStats s on 
		m.ActionId = s.ActionId
order by
	m.ActionId;

-- Garbage collection worker thread statistics
select * 
from sys.dm_db_xtp_gc_cycle_stats;