/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                   Chapter 27. System Troubleshooting                     */
/*                           Memory-related Issues                          */
/****************************************************************************/

/*** Information About Memory Grants ***/
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
option (recompile)
go


/*** Memory Objects Partitioning and Memory Usage ***/
-- SQL Server 2008+
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
	pages_in_bytes desc
go