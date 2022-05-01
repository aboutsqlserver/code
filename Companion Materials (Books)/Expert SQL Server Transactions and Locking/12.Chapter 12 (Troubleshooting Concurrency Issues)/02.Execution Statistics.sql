/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 12. Troubleshooting Concurrency Issues              */
/*	                       Execution Statistics                             */
/****************************************************************************/

/*** Get 50 most expensive queries in terms of I/O with execution plans cached ***/
-- Older versions of SQL Server (and low SPs) may not have some of the columns
-- sys.dm_exec_query_plan is expensive - be careful on busy systems with large 
-- number of plans cached.

-- Raw data - may return > 1 plan per query
select top 50
	substring(qt.text, (qs.statement_start_offset/2)+1,
		((
			case qs.statement_end_offset
				when -1 then datalength(qt.text)
				else qs.statement_end_offset
			end - qs.statement_start_offset)/2)+1) as SQL
	,qs.plan_generation_num
	,qp.query_plan as [Query Plan]
	,qs.execution_count as [Exec Cnt]
	,(qs.total_logical_reads + qs.total_logical_writes) / 
		qs.execution_count as [Avg IO]
	,qs.total_logical_reads as [Total Reads]
	,qs.last_logical_reads as [Last Reads]
	,qs.total_logical_writes as [Total Writes]
	,qs.last_logical_writes as [Last Writes]
	,qs.total_worker_time / 1000 as [Total Worker Time]
	,qs.last_worker_time / 1000 as [Last Worker Time]
	,qs.total_elapsed_time / 1000 as [Total Elapsed Time]
	,qs.last_elapsed_time / 1000 as [Last Elapsed Time]
	,qs.last_execution_time as [Last Exec Time]
	,qs.creation_time as [Cached Time]
	,qs.total_rows as [Total Rows] 
	,qs.last_rows as [Last Rows] 
	,qs.min_rows as [Min Rows]
	,qs.max_rows as [Max Rows] 
	,qs.total_physical_reads as [Total Physical Reads]
	,qs.last_physical_reads as [Last Physical Reads]
	,qs.total_physical_reads / qs.execution_count as [Avg Physical Reads]
	,qs.total_grant_kb as [Total Grant KB]
	,qs.last_grant_kb as [Last Grant KB]
	,(qs.total_grant_kb / qs.execution_count) as [Avg Grant KB] 
	,qs.total_used_grant_kb as [Total Used Grant KB]
	,qs.last_used_grant_kb as [Last Used Grant KB]
	,(qs.total_used_grant_kb / qs.execution_count) as [Avg Used Grant KB] 
	,qs.total_spills as [Total Spills]
	,qs.last_spills as [Last Spills]
	,(qs.total_spills / qs.execution_count) as [Avg Spills]
	,qs.query_hash 
	,qs.query_plan_hash
from 
	sys.dm_exec_query_stats qs with (nolock)
		cross apply sys.dm_exec_sql_text(qs.sql_handle) qt
		cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
order by
	[Avg IO] desc
option (recompile, maxdop 1);
go


-- Aggregating based on query_hash. SQL text is random pick from the group
;with Aggr
as
(
	select 
		qs.query_hash
		,count(*) as [Plan Count]
		,sum(qs.execution_count) as [Exec Cnt]
		,sum(qs.total_logical_reads + qs.total_logical_writes) / 
			sum(qs.execution_count) as [Avg IO]
		,sum(qs.total_logical_reads) as [Total Reads]
		,sum(qs.total_logical_writes) as [Total Writes]
		,sum(qs.total_worker_time) / 1000 as [Total Worker Time]
		,sum(qs.total_elapsed_time) / 1000 as [Total Elapsed Time]
		,max(qs.last_execution_time) as [Last Exec Time]
		,min(qs.creation_time) as [Cached Time]
		,sum(qs.total_rows) as [Total Rows] 
		,sum(qs.total_physical_reads) as [Total Physical Reads]
		,sum(qs.total_physical_reads) / sum(qs.execution_count) as [Avg Physical Reads]
		,sum(qs.total_grant_kb) as [Total Grant KB]
		,sum(qs.total_grant_kb) / sum(qs.execution_count) as [Avg Grant KB] 
		,sum(qs.total_used_grant_kb) as [Total Used Grant KB]
		,sum(qs.total_used_grant_kb) / sum(qs.execution_count) as [Avg Used Grant KB] 
		,sum(qs.total_spills) as [Total Spills]
		,sum(qs.total_spills) / sum(qs.execution_count) as [Avg Spills]
	from 
		sys.dm_exec_query_stats qs with (nolock)
	group by 
		qs.query_hash
)
select 
	qs.*, a.*
from 
	Aggr a 
		outer apply
		(
			select top 1 qt.text as [SQL], qp.query_plan as [Plan]
			from 
				sys.dm_exec_query_stats qs with (nolock)
					cross apply sys.dm_exec_sql_text(qs.sql_handle) qt
					cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
			where
				qs.query_hash = a.query_hash and 
				isnull(qt.text,'') <> ''
		) qs
order by
	a.[Avg IO] desc
option (recompile, maxdop 1);

-- Aggregating based on query_plan_hash. SQL text is random pick from the group
;with Aggr
as
(
	select 
		qs.query_plan_hash
		,count(*) as [Plan Count]
		,sum(qs.execution_count) as [Exec Cnt]
		,sum(qs.total_logical_reads + qs.total_logical_writes) / 
			sum(qs.execution_count) as [Avg IO]
		,sum(qs.total_logical_reads) as [Total Reads]
		,sum(qs.total_logical_writes) as [Total Writes]
		,sum(qs.total_worker_time) / 1000 as [Total Worker Time]
		,sum(qs.total_elapsed_time) / 1000 as [Total Elapsed Time]
		,max(qs.last_execution_time) as [Last Exec Time]
		,min(qs.creation_time) as [Cached Time]
		,sum(qs.total_rows) as [Total Rows] 
		,sum(qs.total_physical_reads) as [Total Physical Reads]
		,sum(qs.total_physical_reads) / sum(qs.execution_count) as [Avg Physical Reads]
		,sum(qs.total_grant_kb) as [Total Grant KB]
		,sum(qs.total_grant_kb) / sum(qs.execution_count) as [Avg Grant KB] 
		,sum(qs.total_used_grant_kb) as [Total Used Grant KB]
		,sum(qs.total_used_grant_kb) / sum(qs.execution_count) as [Avg Used Grant KB] 
		,sum(qs.total_spills) as [Total Spills]
		,sum(qs.total_spills) / sum(qs.execution_count) as [Avg Spills]
	from 
		sys.dm_exec_query_stats qs with (nolock)
	group by 
		qs.query_plan_hash
)
select 
	qs.*, a.*
from 
	Aggr a 
		outer apply
		(
			select top 1 qt.text as [SQL], qp.query_plan as [Plan]
			from 
				sys.dm_exec_query_stats qs with (nolock)
					cross apply sys.dm_exec_sql_text(qs.sql_handle) qt
					cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
			where
				qs.query_plan_hash = a.query_plan_hash and 
				isnull(qt.text,'') <> query_plan_hash
		) qs
order by
	a.[Avg IO] desc
option (recompile, maxdop 1);

/*** Get 50 most expensive stored procedures in terms of I/O  with execution plans cached ***/
-- SQL Server 2008+
select top 50
	db_name(ps.database_id) as [DB]
	,object_name(ps.object_id, ps.database_id) as [Proc Name]
	,ps.type_desc as [Type]
	,qp.query_plan as  [Plan]
	,ps.execution_count as [Exec Count]
	,(ps.total_logical_reads + ps.total_logical_writes) / 
		ps.execution_count as [Avg IO]
	,ps.total_logical_reads as [Total Reads]
	,ps.last_logical_reads as [Last Reads]
	,ps.total_logical_writes as [Total Writes]
	,ps.last_logical_writes as [Last Writes]
	,ps.total_worker_time / 1000 as [Total Worker Time]
	,ps.last_worker_time / 1000 as [Last Worker Time]
	,ps.total_elapsed_time / 1000 as [Total Elapsed Time]
	,ps.last_elapsed_time / 1000 as [Last Elapsed Time]
	,ps.last_execution_time as [Last Exec Time]
	,ps.cached_time as [Cached Time]
	,ps.total_physical_reads as [Total Physical Reads]
	,ps.last_physical_reads as [Last Physical Reads]
	,ps.total_physical_reads / ps.execution_count as [Avg Physical Reads]
	,ps.total_spills as [Total Spills]
	,ps.last_spills as [Last Spills]
	,(ps.total_spills / ps.execution_count) as [Avg Spills]
from 
	sys.dm_exec_procedure_stats ps with (nolock) 
		cross apply sys.dm_exec_query_plan(ps.plan_handle) qp
order by
	[Avg IO] desc
option (recompile, maxdop 1);
go

/*** Get 50 most expensive scalar user-defined functions in terms of I/O with execution plans cached ***/
-- SQL Server 2016
select top 50
	db_name(fs.database_id) as [DB]
	,object_name(fs.object_id, fs.database_id) as [Function]
	,fs.type_desc as [Type]
	,qp.query_plan as  [Plan]
	,fs.execution_count as [Exec Count]
	,(fs.total_logical_reads + fs.total_logical_writes) / 
		fs.execution_count as [Avg IO]
	,fs.total_logical_reads as [Total Reads]
	,fs.last_logical_reads as [Last Reads]
	,fs.total_logical_writes as [Total Writes]
	,fs.last_logical_writes as [Last RWrites]
	,fs.total_worker_time / 1000 as [Total Worker Time]
	,fs.last_worker_time / 1000 as [Last Worker Time]
	,fs.total_elapsed_time / 1000 as [Total Elapsed Time]
	,fs.last_elapsed_time / 1000 as [Last Elapsed Time]
	,fs.last_execution_time as [Last Exec Time]
	,fs.cached_time as [Cached Time]
	,fs.total_physical_reads as [Total Physical Reads]
	,fs.last_physical_reads as [Last Physical Reads]
	,fs.total_physical_reads / fs.execution_count as [Avg Physical Reads]
from 
	sys.dm_exec_function_stats fs with (nolock) 
		cross apply sys.dm_exec_query_plan(fs.plan_handle) qp
order by
	[Avg IO] desc
option (recompile, maxdop 1);
go

/*** Get 50 most expensive triggers in terms of I/O  with execution plans cached ***/
-- SQL Server 2008+
select top 50
	db_name(ts.database_id) as [DB]
	,object_name(ts.object_id, ts.database_id) as [Proc Name]
	,ts.type_desc as [Type]
	,qp.query_plan as  [Plan]
	,ts.execution_count as [Exec Count]
	,(ts.total_logical_reads + ts.total_logical_writes) / 
		ts.execution_count as [Avg IO]
	,ts.total_logical_reads as [Total Reads]
	,ts.last_logical_reads as [Last Reads]
	,ts.total_logical_writes as [Total Writes]
	,ts.last_logical_writes as [Last Writes]
	,ts.total_worker_time / 1000 as [Total Worker Time]
	,ts.last_worker_time / 1000 as [Last Worker Time]
	,ts.total_elapsed_time / 1000 as [Total Elapsed Time]
	,ts.last_elapsed_time / 1000 as [Last Elapsed Time]
	,ts.last_execution_time as [Last Exec Time]
	,ts.cached_time as [Cached Time]
	,ts.total_physical_reads as [Total Physical Reads]
	,ts.last_physical_reads as [Last Physical Reads]
	,ts.total_physical_reads / ts.execution_count as [Avg Physical Reads]
	,ts.total_spills as [Total Spills]
	,ts.last_spills as [Last Spills]
	,(ts.total_spills / ts.execution_count) as [Avg Spills]
from 
	sys.dm_exec_trigger_stats ts with (nolock) 
		cross apply sys.dm_exec_query_plan(ts.plan_handle) qp
order by
	[Avg IO] desc
option (recompile, maxdop 1);
go
