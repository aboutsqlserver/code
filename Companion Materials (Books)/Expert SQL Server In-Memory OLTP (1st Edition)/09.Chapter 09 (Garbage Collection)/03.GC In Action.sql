/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 09: Garbage Collection                       */
/*                            03.GC In Action                               */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

create table #MemStats
(
	ActionId int not null identity(1,1),
	Action varchar(32) not null,
	TblAllocatedMemory int not null,
	TblUsedMemory int not null
);

create table #IdxStats
(
	ActionId int not null identity(1,1),
	Action varchar(32) not null,
	RowsTouched int not null,
	RowsExpired int not null,
	RowsExpiredRemoved int not null,
);

create table #GCStats
(
	ActionId int not null identity(1,1),
	Action varchar(32) not null,
	TotalEnqueues int not null,
	TotalDequeues int not null,
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
	where object_id = OBJECT_ID(N'dbo.GCDemo');

insert into #GCStats(Action,TotalEnqueues,TotalDequeues)
	select 'Initial', sum(total_enqueues), sum(total_dequeues)
	from sys.dm_xtp_gc_queue_stats 
go

declare
	@I int = 1

while @I <= 1500 -- Change to 32768 to see GC activated based on the load
begin
	delete from dbo.GCDemo with (snapshot) where ID = @I
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
	from sys.dm_xtp_gc_queue_stats 
go

select count(*) from dbo.GCDemo;

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
	from sys.dm_xtp_gc_queue_stats 
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
	from sys.dm_xtp_gc_queue_stats 
go

select count(*) from dbo.GCDemo;
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
	from sys.dm_xtp_gc_queue_stats 
go

select 
	m.Action as Stage
    ,convert(decimal(7,2), m.TblAllocatedMemory / 1024.)
		as [Alloc Memory]
    ,convert(decimal(7,2),m.TblUsedMemory / 1024.)
		as [Used Memory]
	,rowstouched as [Touched]
	, rowsexpired as [Expired]
	, rowsexpiredremoved as Removed
	,totalenqueues as [Enqueues]
    ,totaldequeues as [Dequeues]
from 
    #MemStats m join #IdxStats i on
		m.ActionId = i.ActionId
	join #GCStats g on 
		m.ActionId = g.ActionId
order by
	m.ActionId
