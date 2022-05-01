/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 12. Troubleshooting Concurrency Issues              */
/*                       Index Usage from Plan Cache                        */
/****************************************************************************/

-- The scripts are heavy and will introduce the overhead on the systems with large number of plans in the cach

-- Simple version
declare
	@IndexName sysname = quotename('IDX_CI');

;with xmlnamespaces(default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')  
,Data
as
(
	select distinct
		obj.value('@Database','sysname') as [Database]
		,obj.value('@Schema','sysname') + '.' + obj.value('@Table','sysname') as [Table]
		,obj.value('@Index','sysname') as [Index]
		,obj.value('@IndexKind','varchar(64)') as [Type]
		,stmt.value('@StatementText', 'nvarchar(max)') as [Statement]
		,convert(nvarchar(max),qp.query_plan) as query_plan
	from
		sys.dm_exec_cached_plans cp with (nolock) 
			cross apply sys.dm_exec_query_plan(cp.plan_handle) qp
			cross apply qp.query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') batch(stmt)
			cross apply stmt.nodes('.//IndexScan/Object[@Index=sql:variable("@IndexName")]') idx(obj)
)
select 
	[Database]
	,[Table]
	,[Index]
	,[Type]
	,[Statement]
	,convert(xml,query_plan) as query_plan
from Data
option (recompile, maxdop 1)
go

-- More stats - has overhead
declare
	@IndexName sysname = quotename('IDX_CI');

;with xmlnamespaces(default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')  
,CachedData
as
(
	select distinct
		obj.value('@Database','sysname') as [Database]
		,obj.value('@Schema','sysname') + '.' + obj.value('@Table','sysname') as [Table]
		,obj.value('@Index','sysname') as [Index]
		,obj.value('@IndexKind','varchar(64)') as [Type]
		,stmt.value('@StatementText', 'nvarchar(max)') as [Statement]
		,convert(nvarchar(max),qp.query_plan) as query_plan
		,cp.plan_handle
	from
		sys.dm_exec_cached_plans cp with (nolock) 
			cross apply sys.dm_exec_query_plan(plan_handle) qp
			cross apply query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') batch(stmt)
			cross apply stmt.nodes('.//IndexScan/Object[@Index=sql:variable("@IndexName")]') idx(obj)
)
select
	cd.[Database]
	,cd.[Table]
	,cd.[Index]
	,cd.[Type]
	,cd.[Statement]
	,convert(xml,cd.query_plan) as query_plan
	,qs.execution_count
	,(qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count as [Avg IO]
	,qs.total_logical_reads
	,qs.total_logical_writes
	,qs.total_worker_time
	,qs.total_worker_time / qs.execution_count / 1000 as [Avg Worker Time (ms)]
	,qs.total_rows
	,qs.creation_time
	,qs.last_execution_time
from 
	CachedData cd
		outer apply
		(
			select 
				sum(qs.execution_count) as execution_count
				,sum(qs.total_logical_reads) as total_logical_reads 
				,sum(qs.total_logical_writes) as total_logical_writes
				,sum(qs.total_worker_time) as total_worker_time
				,sum(qs.total_rows) as total_rows
				,min(qs.creation_time) as creation_time 
				,max(qs.last_execution_time) as last_execution_time
			from sys.dm_exec_query_stats qs with (nolock)
			where qs.plan_handle = cd.plan_handle
		) qs
option (recompile, maxdop 1)