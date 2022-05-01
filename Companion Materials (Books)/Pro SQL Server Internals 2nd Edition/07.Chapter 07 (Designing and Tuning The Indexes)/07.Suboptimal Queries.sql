/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 07. Designing and Tuning The Indexes               */
/*                           Suboptimal Queries                             */
/****************************************************************************/


/****************************************************************************/
/*                More on the topic in Chapters 28 and 29                   */
/****************************************************************************/

select top 50 
	substring(qt.text, (qs.statement_start_offset/2)+1,
		((
			case qs.statement_end_offset
				when -1 then datalength(qt.text)
				else qs.statement_end_offset
			end - qs.statement_start_offset)/2)+1) as [Sql]
	,qs.execution_count as [Exec Cnt]
	,(qs.total_logical_reads + qs.total_logical_writes) 
		/ qs.execution_count as [Avg IO]
	,qp.query_plan as [Plan]
	,qs.total_logical_reads as [Total Reads]
	,qs.last_logical_reads as [Last Reads]
	,qs.total_logical_writes as [Total Writes]
	,qs.last_logical_writes as [Last Writes]
	,qs.total_worker_time as [Total Worker Time]
	,qs.last_worker_time as [Last Worker Time]
	,qs.total_elapsed_time/1000 as [Total Elps Time]
	,qs.last_elapsed_time/1000 as [Last Elps Time]
	,qs.creation_time as [Compile Time]
	,qs.last_execution_time as [Last Exec Time]
from
	sys.dm_exec_query_stats qs with (nolock)
		cross apply sys.dm_exec_sql_text(qs.sql_handle) qt
		cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
order by
	[Avg IO] desc
option (recompile) ;
go

-- Requires SQL Server 2008+
select top 50
	s.name + '.' + p.name as [Procedure]
	,qp.query_plan as [Plan]
	,(ps.total_logical_reads + ps.total_logical_writes) / 
		ps.execution_count as [Avg IO]
	,ps.execution_count as [Exec Cnt]
	,ps.cached_time as [Cached]
	,ps.last_execution_time as [Last Exec Time]
	,ps.total_logical_reads as [Total Reads]
	,ps.last_logical_reads as [Last Reads]
	,ps.total_logical_writes as [Total Writes]
	,ps.last_logical_writes as [Last Writes]
	,ps.total_worker_time as [Total Worker Time]  
	,ps.last_worker_time as [Last Worker Time]  
	,ps.total_elapsed_time as [Total Elapsed Time]
	,ps.last_elapsed_time as [Last Elapsed Time]
from	
	sys.procedures as p with (nolock) join sys.schemas s with (nolock) on	
		p.schema_id = s.schema_id
	join sys.dm_exec_procedure_stats as ps with (nolock) on 
		p.object_id = ps.object_id
	outer apply sys.dm_exec_query_plan(ps.plan_handle) qp
order by 
	[Avg IO] desc
option	(recompile);
go
