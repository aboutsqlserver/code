/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 28. System Troubleshooting                     */
/*                           Memory-related Issues                          */
/****************************************************************************/

-- Information About Memory Grants 
select 
	mg.session_id
	,t.text as [SQL]
	,qp.query_plan as [Plan]
	--,mg.is_small -- SQL Server 2008+
	,mg.dop	
	,mg.query_cost
	,mg.request_time
	,mg.required_memory_kb
	,mg.requested_memory_kb
	,mg.wait_time_ms
	,mg.grant_time
	,mg.granted_memory_kb
	,mg.used_memory_kb
	,mg.max_used_memory_kb
from 
	sys.dm_exec_query_memory_grants mg with (nolock)
		cross apply sys.dm_exec_sql_text(mg.sql_handle) t
		cross apply sys.dm_exec_query_plan(mg.plan_handle) as qp
option (recompile);
go

-- Memory Grant Statistics: 
-- SQL Server 2012 SP3, 2014 SP2 and 2016 expose the information in sys.dm_exec_query_stats.
select top 50
	substring(qt.text, (qs.statement_start_offset/2)+1,
		((
			case qs.statement_end_offset
				when -1 then datalength(qt.text)
				else qs.statement_end_offset
			end - qs.statement_start_offset)/2)+1) as SQL
	,qp.query_plan as [Query Plan]
	,qs.execution_count as [Exec Cnt]
	-- SQL Server 2012 SP3, SQL Server 2014 SP2, SQL Server 2016: BEGIN
	,qs.total_grant_kb as [Total Memory Grant KB] -- since the time query was sompiled
	,qs.last_grant_kb as [Last Memory Grant KB] 
	,(qs.total_grant_kb / qs.execution_count) as [Avg Memory Grant KB]
	,qs.total_used_grant_kb as [Total Used Memory Grant KB] -- since the time query was sompiled
	,qs.last_used_grant_kb as [Last Used Memory Grant KB] 
	,(qs.total_used_grant_kb / qs.execution_count) as [Avg Used Memory Grant KB]
	,qs.total_ideal_grant_kb as [Total Ideal Memory Grant KB] -- since the time query was sompiled
	,qs.last_ideal_grant_kb as [Last Ideal Memory Grant KB] 
	,(qs.total_ideal_grant_kb / qs.execution_count) as [Avg Ideal Memory Grant KB]
	-- SQL Server 2012 SP3, SQL Server 2014 SP2, SQL Server 2016: END
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
	,qs.total_rows as [Total Rows] 
	,qs.last_rows as [Last Rows] 
	,qs.min_rows as [Min Rows] 
	,qs.max_rows as [Max Rows]  
from 
	sys.dm_exec_query_stats qs with (nolock)
		cross apply sys.dm_exec_sql_text(qs.sql_handle) qt
		cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
order by
	[Avg Memory Grant KB] desc
option (recompile);
go

-- Earlier verions - can get the limited data from the plan. 
;with xmlnamespaces(default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
,Statements(PlanHandle, ObjType, UseCount, StmtSimple)
as
(
    select cp.plan_handle, cp.objtype, cp.usecounts, nodes.stmt.query('.')
    from sys.dm_exec_cached_plans cp with (nolock)
        cross apply sys.dm_exec_query_plan(cp.plan_handle) qp
        cross apply qp.query_plan.nodes('//StmtSimple') nodes(stmt)
)
select top 50
    s.PlanHandle, qp.query_plan, s.ObjType, s.UseCount
    ,p.qp.value('@CachedPlanSize','int') as CachedPlanSize
    ,mg.mg.value('@SerialRequiredMemory','int') as [SerialRequiredMemory KB]
    ,mg.mg.value('@SerialDesiredMemory','int') as [SerialDesiredMemory KB]
from Statements s
    cross apply s.StmtSimple.nodes('.//QueryPlan') p(qp)
    cross apply p.qp.nodes('.//MemoryGrantInfo') mg(mg)
	cross apply sys.dm_exec_query_plan(s.PlanHandle) qp
order by 
    mg.mg.value('@SerialRequiredMemory','int') desc;
go


/*** Memory Objects Partitioning and Memory Usage ***/
-- SQL Server 2008+. Do not need in SQL Server 2016
select
	type
	,pages_in_bytes
	, case
		when (creation_options & 0x20 = 0x20) 
			then 'Global PMO. Cannot be partitioned by CPU/NUMA Node. T8048 not applicable.'
		when (creation_options & 0x40 = 0x40) 
			then 'Partitioned by CPU. T8048 not applicable.'
		when (creation_options & 0x80 = 0x80) 
			then 'Partitioned by Node. Use T8048 to further partition by CPU.'
		else
			'Unknown'      
	end as [Partitioning Type]
from 
	sys.dm_os_memory_objects
order by 
	pages_in_bytes desc;
go

-- What is using Memory
select top 10 
    [type] as [Memory Clerk]
    ,convert(decimal(16,3),sum(pages_kb) / 1024.0) as [Memory Usage(MB)]  
from sys.dm_os_memory_clerks with (nolock)
group by [type]  
order by sum(pages_kb) desc;
go

-- More detailed
dbcc memorystatus;
go

