/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 12. Troubleshooting Concurrency Issues              */
/*                           Wait Statistics                                */
/****************************************************************************/

/*** Clearing Waits ***/
-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR) 

/*** Checking Top Waits in the System ***/
;with Waits
as
(
	select 
		wait_type, wait_time_ms, waiting_tasks_count,signal_wait_time_ms
		,wait_time_ms - signal_wait_time_ms as resource_wait_time_ms
		,100. * wait_time_ms / SUM(wait_time_ms) over() as Pct
		,row_number() over(order by wait_time_ms desc) AS RowNum
	from sys.dm_os_wait_stats with (nolock)
	where 
		wait_type not in /* Filtering out non-essential system waits */
		(N'BROKER_EVENTHANDLER',N'BROKER_RECEIVE_WAITFOR',N'BROKER_TASK_STOP'
		,N'BROKER_TO_FLUSH',N'BROKER_TRANSMITTER',N'CHECKPOINT_QUEUE',N'CHKPT'
		,N'CLR_SEMAPHORE',N'CLR_AUTO_EVENT',N'CLR_MANUAL_EVENT'
		,N'DBMIRROR_DBM_EVENT',N'DBMIRROR_EVENTS_QUEUE',N'DBMIRROR_WORKER_QUEUE'
		,N'DBMIRRORING_CMD',N'DIRTY_PAGE_POLL',N'DISPATCHER_QUEUE_SEMAPHORE'
		,N'EXECSYNC',N'FSAGENT',N'FT_IFTS_SCHEDULER_IDLE_WAIT',N'FT_IFTSHC_MUTEX'
		,N'HADR_CLUSAPI_CALL',N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',N'HADR_LOGCAPTURE_WAIT'
		,N'HADR_NOTIFICATION_DEQUEUE',N'HADR_TIMER_TASK',N'HADR_WORK_QUEUE'
		,N'KSOURCE_WAKEUP',N'LAZYWRITER_SLEEP',N'LOGMGR_QUEUE' 
		,N'MEMORY_ALLOCATION_EXT',N'ONDEMAND_TASK_QUEUE',N'PARALLEL_REDO_WORKER_WAIT_WORK'
		,N'PREEMPTIVE_HADR_LEASE_MECHANISM',N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS'
		,N'PREEMPTIVE_OS_LIBRARYOPS',N'PREEMPTIVE_OS_COMOPS',N'PREEMPTIVE_OS_CRYPTOPS'
		,N'PREEMPTIVE_OS_PIPEOPS', N'PREEMPTIVE_OS_AUTHENTICATIONOPS'
		,N'PREEMPTIVE_OS_GENERICOPS',N'PREEMPTIVE_OS_VERIFYTRUST',N'PREEMPTIVE_OS_FILEOPS'
		,N'PREEMPTIVE_OS_DEVICEOPS',N'PREEMPTIVE_OS_QUERYREGISTRY'
		,N'PREEMPTIVE_OS_WRITEFILE',N'PREEMPTIVE_XE_CALLBACKEXECUTE'
		,N'PREEMPTIVE_XE_DISPATCHER',N'PREEMPTIVE_XE_GETTARGETSTATE'
		,N'PREEMPTIVE_XE_SESSIONCOMMIT',N'PREEMPTIVE_XE_TARGETINIT'
		,N'PREEMPTIVE_XE_TARGETFINALIZE',N'PWAIT_ALL_COMPONENTS_INITIALIZED'
		,N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP'
		,N'QDS_ASYNC_QUEUE',N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP'
		,N'REQUEST_FOR_DEADLOCK_SEARCH',N'RESOURCE_QUEUE',N'SERVER_IDLE_CHECK'
		,N'SLEEP_BPOOL_FLUSH',N'SLEEP_DBSTARTUP',N'SLEEP_DCOMSTARTUP'
		,N'SLEEP_MASTERDBREADY',N'SLEEP_MASTERMDREADY',N'SLEEP_MASTERUPGRADED'
		,N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',N'SLEEP_TEMPDBSTARTUP'
		,N'SNI_HTTP_ACCEPT',N'SP_SERVER_DIAGNOSTICS_SLEEP',N'SQLTRACE_BUFFER_FLUSH'
		,N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',N'SQLTRACE_WAIT_ENTRIES',N'WAIT_FOR_RESULTS'
		,N'WAITFOR',N'WAITFOR_TASKSHUTDOWN',N'WAIT_XTP_HOST_WAIT'
		,N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',N'WAIT_XTP_CKPT_CLOSE',N'WAIT_XTP_RECOVERY'
		,N'XE_BUFFERMGR_ALLPROCESSED_EVENT', N'XE_DISPATCHER_JOIN',N'XE_DISPATCHER_WAIT'
		,N'XE_LIVE_TARGET_TVF',N'XE_TIMER_EVENT')
	--and wait_time_ms > 0
)
select
	w1.wait_type as [Wait Type]
	,w1.waiting_tasks_count as [Wait Count]
	,convert(decimal(12,3), w1.wait_time_ms / 1000.0) as [Wait Time]
	,convert(decimal(12,1), w1.wait_time_ms / w1.waiting_tasks_count) as [Avg Wait Time]
	,convert(decimal(12,3), w1.signal_wait_time_ms / 1000.0) as [Signal Wait Time]
	,convert(decimal(12,1), w1.signal_wait_time_ms / w1.waiting_tasks_count) as [Avg Signal Wait Time]
	,convert(decimal(12,3), w1.resource_wait_time_ms / 1000.0) as [Resource Wait Time]
	,convert(decimal(12,1), w1.resource_wait_time_ms / w1.waiting_tasks_count) as [Avg Resource Wait Time]
	,convert(decimal(6,3), w1.Pct) as [Percent]
	,convert(decimal(6,3), w1.Pct + IsNull(w2.Pct,0)) as [Running Percent]
from
	Waits w1 cross apply
	(
		select sum(w2.Pct) as Pct
		from Waits w2
		where w2.RowNum < w1.RowNum
	) w2
where
	w1.RowNum = 1 or w2.Pct <= 99
order by
	w1.RowNum 
option (recompile);
go

/*** Comparing Signal and Resource Waits ***/
select 
	sum(signal_wait_time_ms) as [Signal Wait Time (ms)]
	,convert(decimal(7,4), 100.0 * sum(signal_wait_time_ms) / 
		sum (wait_time_ms)) as [% Signal waits]
	,sum(wait_time_ms - signal_wait_time_ms) as [Resource Wait Time (ms)]
	,convert(decimal(7,4), 100.0 * sum(wait_time_ms - signal_wait_time_ms) / 
		sum (wait_time_ms)) as [% Resource waits]
from
	sys.dm_os_wait_stats with (nolock)
option (recompile);
go


/*** List of currently waiting tasks ***/
select
	wt.session_id
	,wt.wait_type
	,wt.wait_duration_ms
	,wt.blocking_session_id
	,wt.resource_description
from 
	sys.dm_os_waiting_tasks wt with (nolock)
order by 
	wt.wait_duration_ms desc
option (recompile);


/*** Obtaining information about blocking session ***/
select
	ec.session_id
	,s.login_time 
	,s.host_name
	,s.program_name
	,s.login_name
	,s.original_login_name
	,ec.connect_time
	,qt.text as [SQL]
from 
	sys.dm_exec_connections ec with (nolock) 
		join sys.dm_exec_sessions s with (nolock) on
			ec.session_id = s.session_id
		cross apply 
			sys.dm_exec_sql_text(ec.most_recent_sql_handle) qt
where
	ec.session_id = 51 -- session id of the blocking session
option (recompile);
go

-- SQL Server 2016+. Session-Level waits
select * 
from sys.dm_exec_session_wait_stats 
where session_id = 63; 