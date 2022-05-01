/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                        Chapter 29. Query Store                           */
/*                       Working with Query Store                           */
/****************************************************************************/

set noexec off
go

if convert(int,
		left(
			convert(nvarchar(128), serverproperty('ProductVersion')),
			charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
		)
	) < 13
begin
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

use SQLServerInternals
go

/* SQL Server 2016 RTM/CU1 has the bug that incorrectly displays text representation of the query plan in some cases */

-- Getting most expensive queries from the cache
select top 50 
	q.query_id, qt.query_sql_text, qp.plan_id, qp.query_plan
	,sum(rs.count_executions) as [Execution Cnt]
	,convert(int,sum(rs.count_executions * 
		(rs.avg_logical_io_reads + avg_logical_io_writes)) / 
			sum(rs.count_executions)) as [Avg IO]
	,convert(int,sum(rs.count_executions * 
		(rs.avg_logical_io_reads + avg_logical_io_writes))) as [Total IO]
	,convert(int,sum(rs.count_executions * rs.avg_cpu_time) /
		sum(rs.count_executions)) as [Avg CPU]
	,convert(int,sum(rs.count_executions * rs.avg_cpu_time)) as [Total CPU]
	,convert(int,sum(rs.count_executions * rs.avg_duration) / 
		sum(rs.count_executions)) as [Avg Duration]
	,convert(int,sum(rs.count_executions * rs.avg_duration)) 
		as [Total Duration]
	,convert(int,sum(rs.count_executions * rs.avg_physical_io_reads) / 
		sum(rs.count_executions)) as [Avg Physical Reads]
	,convert(int,sum(rs.count_executions * rs.avg_physical_io_reads)) 
		as [Total Physical Reads]
	,convert(int,sum(rs.count_executions * rs.avg_query_max_used_memory) / 
		sum(rs.count_executions)) as [Avg Memory Grant Pages]
	,convert(int,sum(rs.count_executions * rs.avg_query_max_used_memory)) 
		as [Total Memory Grant Pages]
	,convert(int,sum(rs.count_executions * rs.avg_rowcount) /
		sum(rs.count_executions)) as [Avg Rows]
	,convert(int,sum(rs.count_executions * rs.avg_rowcount)) as [Total Rows]
	,convert(int,sum(rs.count_executions * rs.avg_dop) /
		sum(rs.count_executions)) as [Avg DOP]
	,convert(int,sum(rs.count_executions * rs.avg_dop)) as [Total DOP]
from 
	sys.query_store_query q join sys.query_store_plan qp on
		q.query_id = qp.query_id
	join sys.query_store_query_text qt on
		q.query_text_id = qt.query_text_id
	join sys.query_store_runtime_stats rs on
		qp.plan_id = rs.plan_id 
	join sys.query_store_runtime_stats_interval rsi on
		rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
where
	rsi.end_time >= dateadd(day,-1,getdate())
group by
	q.query_id, qt.query_sql_text, qp.plan_id, qp.query_plan
order by 
	[Avg IO] desc;

-- Looking for regressions
;with Regressions(query_id, query_text_id, plan1_id, plan2_id, plan1
	,plan2, dur1, dur2, row_num)
as
(
	select 
		q.query_id, q.query_text_id, qp1.plan_id, q2.plan_id
		,qp1.query_plan, q2.query_plan, rs1.avg_duration, q2.avg_duration
		,row_number() over (partition by qp1.plan_id order by rs1.avg_duration) 
	from 
		sys.query_store_query q join sys.query_store_plan qp1 on
			q.query_id = qp1.query_id
		join sys.query_store_runtime_stats rs1 on
			qp1.plan_id = rs1.plan_id 
		join sys.query_store_runtime_stats_interval rsi1 on
			rs1.runtime_stats_interval_id = rsi1.runtime_stats_interval_id
		cross apply
		(
			select top 1 
				qp2.query_plan, qp2.plan_id, rs2.avg_duration
			from 
				sys.query_store_plan qp2 
					join sys.query_store_runtime_stats rs2 on
						qp2.plan_id = rs2.plan_id 
				join sys.query_store_runtime_stats_interval rsi2 on
						rs2.runtime_stats_interval_id = 
							rsi2.runtime_stats_interval_id
			where
				q.query_id = qp2.query_id and
				qp1.plan_id <> qp2.plan_id and 
				rsi1.start_time < rsi2.start_time and
				rs1.avg_duration * 2 <= rs2.avg_duration 
			order by
				rs2.avg_duration desc
		) q2
	where
		rsi1.start_time >= dateadd(day,-3,getdate())
)
select 
	r.query_id, qt.query_sql_text, r.plan1_id, r.plan1, r.plan2_id, r.plan2
	,r.dur1, r.dur2
from
	Regressions r join sys.query_store_query_text qt  on
		r.query_text_id = qt.query_text_id
where 
	r.row_num = 1 
order by 
	r.dur2 / r.dur1 desc;

-- Forcing / Unforcing Query Plan
exec sys.sp_query_store_force_plan @query_id = <>, @plan_id = <>;
exec sys.sp_query_store_unforce_plan @query_id = <>, @plan_id = <>;
go


-- Queries with multiple context setttings
select 
	q.query_id, qt.query_sql_text
	,count(distinct q.context_settings_id) as [Context Setting Cnt]
	,count(distinct qp.plan_id) as [Plan Count]
from 
	sys.query_store_query q join sys.query_store_query_text qt on
		q.query_text_id = qt.query_text_id
	join sys.query_store_plan qp on
		q.query_id = qp.query_id
group by
	q.query_id, qt.query_sql_text
having
	count(distinct q.context_settings_id) > 1
order by 
	count(distinct q.context_settings_id);

-- Similar queries
select top 100 
	q.query_hash
	,count(*) as [Query Count]
	,avg(rs.count_executions) as [Avg Exec Count]
from 
	sys.query_store_query q join sys.query_store_plan qp on
		q.query_id = qp.query_id
	join sys.query_store_runtime_stats rs on
		qp.plan_id = rs.plan_id 
group by 
	q.query_hash
having 
	count(*) > 1
order by 
	[Avg Exec Count] asc, [Query Count] desc;

