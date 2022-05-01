/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 12: Deployment and Management                    */
/*                        05.Execution Statistics                           */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

/*** Enable Execution Statistics Collection. Do not keep enabled on production server ***/
exec sys.sp_xtp_control_proc_exec_stats 1;
exec sys.sp_xtp_control_query_exec_stats 1;
go

-- dbcc freeproccache
-- alter database scoped configuration clear procedure_cache

-- exec sp_recompile 'Delivery.InsertOrder'

select 
	object_name(ps.object_id) as [Proc Name]
	,p.query_plan
	,ps.execution_count as [Exec Cnt]
	,ps.total_worker_time as [Total CPU]
	,convert(int,ps.total_worker_time / ps.execution_count) 
		as [Avg CPU] -- in Microseconds
	,ps.total_elapsed_time as [Total Elps]
	,convert(int,ps.total_elapsed_time / ps.execution_count) 
		as [Avg Elps] -- in Microseconds
	,ps.cached_time as [Cached]
	,ps.last_execution_time as [Last Exec]  
	,ps.sql_handle
	,ps.plan_handle
	,ps.total_logical_reads as [Reads]
	,ps.total_logical_writes as [Writes]
from 
	sys.dm_exec_procedure_stats ps cross apply 
		sys.dm_exec_query_plan(ps.plan_handle) p
order by
	[Avg CPU] desc
go

select 
	substring(qt.text
		,(qs.statement_start_offset/2) + 1
		,(case qs.statement_end_offset
			when -1 then datalength(qt.text)
			else qs.statement_end_offset
		end - qs.statement_start_offset) / 2 + 1 
	) as SQL
	,p.query_plan
	,qs.execution_count as [Exec Cnt]
	,qs.total_worker_time as [Total CPU]
	,convert(int,qs.total_worker_time / qs.execution_count) 
		as [Avg CPU] -- in Microseconds
	,total_elapsed_time as [Total Elps]
	,convert(int,qs.total_elapsed_time / qs.execution_count) 
		as [Avg Elps] -- in Microseconds
	,qs.creation_time as [Cached]
	,last_execution_time as [Last Exec]  
	,qs.plan_handle
	,qs.total_logical_reads as [Reads]
	,qs.total_logical_writes as [Writes]
from 
	sys.dm_exec_query_stats qs
		cross apply sys.dm_exec_sql_text(qs.sql_handle) qt
		cross apply sys.dm_exec_query_plan(qs.plan_handle) p
where -- it is null for natively compiled SPs
	qs.plan_generation_num is null 
order by 
	[Avg CPU] desc
go
