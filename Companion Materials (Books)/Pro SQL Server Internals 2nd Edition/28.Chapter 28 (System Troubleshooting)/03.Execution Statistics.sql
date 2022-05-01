/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 28. System Troubleshooting                     */
/*	                       Execution Statistics                             */
/****************************************************************************/

/*** Get 50 most expensive queries in terms of I/O with execution plans cached ***/
-- SQL Server 2012 SP3, 2014 SP2 and 2016 expose the information about memory grants.
-- You can use it to troubleshoot excessive memory usage 
select top 50
	substring(qt.text, (qs.statement_start_offset/2)+1,
		((
			case qs.statement_end_offset
				when -1 then datalength(qt.text)
				else qs.statement_end_offset
			end - qs.statement_start_offset)/2)+1) as SQL
	,qp.query_plan as [Query Plan]
	,qs.execution_count as [Exec Cnt]
	,(qs.total_logical_reads + qs.total_logical_writes) / 
		qs.execution_count as [Avg IO]
	,qs.total_logical_reads as [Total Reads]
	,qs.last_logical_reads as [Last Reads]
	,qs.total_logical_writes as [Total Writes]
	,qs.last_logical_writes as [Last Writes]
	,qs.total_worker_time as [Total Worker Time]
	,qs.last_worker_time as [Last Worker Time]
	,qs.total_elapsed_time / 1000 as [Total Elapsed Time]
	,qs.last_elapsed_time / 1000 as [Last Elapsed Time]
	,qs.last_execution_time as [Last Exec Time]
	,qs.creation_time as [Cached Time]
	,qs.total_rows as [Total Rows] -- SQL Server 2008R2+
	,qs.last_rows as [Last Rows] -- SQL Server 2008R2+
	,qs.min_rows as [Min Rows] -- SQL Server 2008R2+
	,qs.max_rows as [Max Rows] -- SQL Server 2008R2+ 
from 
	sys.dm_exec_query_stats qs with (nolock)
		cross apply sys.dm_exec_sql_text(qs.sql_handle) qt
		cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
order by
	[Avg IO] desc
option (recompile);
go


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
	,ps.total_worker_time as [Total Worker Time]
	,ps.last_worker_time as [Last Worker Time]
	,ps.total_elapsed_time / 1000 as [Total Elapsed Time]
	,ps.last_elapsed_time / 1000 as [Last Elapsed Time]
	,ps.last_execution_time as [Last Exec Time]
	,ps.cached_time as [Cached Time]
from 
	sys.dm_exec_procedure_stats ps with (nolock) 
		cross apply sys.dm_exec_query_plan(ps.plan_handle) qp
order by
	[Avg IO] desc
option (recompile);
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
	,fs.total_worker_time as [Total Worker Time]
	,fs.last_worker_time as [Last Worker Time]
	,fs.total_elapsed_time / 1000 as [Total Elapsed Time]
	,fs.last_elapsed_time / 1000 as [Last Elapsed Time]
	,fs.last_execution_time as [Last Exec Time]
	,fs.cached_time as [Cached Time]
from 
	sys.dm_exec_function_stats fs with (nolock) 
		cross apply sys.dm_exec_query_plan(fs.plan_handle) qp
order by
	[Avg IO] desc
option (recompile);
go

