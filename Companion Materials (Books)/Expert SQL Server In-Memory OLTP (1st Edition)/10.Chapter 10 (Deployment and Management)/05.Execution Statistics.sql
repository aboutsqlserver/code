/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 10: Deployment and Management                    */
/*                        05.Execution Statistics                           */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

/*** Enable Execution Statistics Collection. Do not keep enabled on production server ***/
exec sys.sp_xtp_control_proc_exec_stats 1;
exec sys.sp_xtp_control_query_exec_stats 1;
go

select 
	object_name(object_id) as [Proc Name]
	,execution_count as [Exec Cnt]
	,total_worker_time as [Total CPU]
	,convert(int,total_worker_time / 1000 / execution_count) 
		as [Avg CPU] -- in Milliseconds
	,total_elapsed_time as [Total Elps]
	,convert(int,total_elapsed_time / 1000 / execution_count) 
		as [Avg Elps] -- in Milliseconds
	,cached_time as [Cached]
	,last_execution_time as [Last Exec]  
	,sql_handle
	,plan_handle
	,total_logical_reads as [Reads]
	,total_logical_writes as [Writes]
from 
	sys.dm_exec_procedure_stats
order by
	[AVG CPU] desc
go

select 
	substring(qt.text
		,(qs.statement_start_offset/2) + 1
		,(case qs.statement_end_offset
			when -1 then datalength(qt.text)
			else qs.statement_end_offset
		end - qs.statement_start_offset) / 2 + 1 
	) as SQL
	,qs.execution_count as [Exec Cnt]
	,qs.total_worker_time as [Total CPU]
	,convert(int,qs.total_worker_time / 1000 / qs.execution_count) 
		as [Avg CPU] -- in Milliseconds
	,total_elapsed_time as [Total Elps]
	,convert(int,qs.total_elapsed_time / 1000 / qs.execution_count) 
		as [Avg Elps] -- in Milliseconds
	,qs.creation_time as [Cached]
	,last_execution_time as [Last Exec]  
	,qs.plan_handle
	,qs.total_logical_reads as [Reads]
	,qs.total_logical_writes as [Writes]
from 
	sys.dm_exec_query_stats qs
		outer apply sys.dm_exec_sql_text(qs.sql_handle) qt
where 
	qs.plan_generation_num is null
order by 
	[AVG CPU] desc
go
