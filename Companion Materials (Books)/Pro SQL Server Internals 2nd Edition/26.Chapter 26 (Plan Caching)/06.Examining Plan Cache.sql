/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 26. Plan Caching                         */
/*                          Examining Plan Cache                            */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

/*** Checking Plan Cache Stores' Size ***/
select 
	type as [Cache Store]
	,sum(pages_in_bytes) / 1024.0 as [Size in KB] -- SQL Server 2012+
	--,sum(pages_allocated_count) * 8.0 as [Size in KB] -- SQL Server <2012
from sys.dm_os_memory_objects
where type in 
	('MEMOBJ_CACHESTORESQLCP','MEMOBJ_CACHESTOREOBJCP'
	,'MEMOBJ_CACHESTOREXPROC','MEMOBJ_SQLMGR')
group by
	type; 
go

/*** Checking Original and Current Cost of Plan Entries ***/
select 
	q.Text as [SQL], p.objtype, p.usecounts, p.size_in_bytes
	,mce.Type as [Cache Store]
	,mce.original_cost, mce.current_cost, mce.disk_ios_count
	,mce.pages_kb  -- SQL Server 2012+
	--,mce.pages_allocated_count * 8.0 as [Pages in KB] -- SQL Server < 2012
	,mce.context_switches_count
	,qp.query_plan
from 
	sys.dm_exec_cached_plans p with (nolock) join
		sys.dm_os_memory_cache_entries mce with (nolock) on
			p.memory_object_address = mce.memory_object_address
	cross apply
		sys.dm_exec_sql_text(p.plan_handle) q
	cross apply
		sys.dm_exec_query_plan(p.plan_handle) qp
where
	p.cacheobjtype = 'Compiled plan' and
	mce.type in (N'CACHESTORE_SQLCP',N'CACHESTORE_OBJCP')
order by
	p.usecounts desc;
go


/*** SQL_Handle and Plan_Handle ***/
dbcc freeproccache
go

set quoted_identifier off
go

select top 1 ID from dbo.Employees where Salary > 40000;
go

set quoted_identifier on
go

select top 1 ID from dbo.Employees where Salary > 40000;
go

;with PlanInfo(sql_handle, plan_handle, set_options)
as
(
	select pvt.sql_handle, pvt.plan_handle, pvt.set_options
	from 
	(
		select p.plan_handle, pa.attribute, pa.value 
		from 
			sys.dm_exec_cached_plans p with (nolock) outer apply 
				sys.dm_exec_plan_attributes(p.plan_handle) pa
		where cacheobjtype = 'Compiled Plan'
	) as pc 
	pivot (max(pc.value) for pc.attribute 
		IN ("set_options", "sql_handle")) AS pvt
)
select pi.sql_handle, pi.plan_handle, pi.set_options, b.text
from 
	PlanInfo pi cross apply 
		sys.dm_exec_sql_text(convert(varbinary(64),pi.sql_handle)) b
option (recompile);
go

/*** Currently-running requests ***/
select
	er.session_id
	,er.user_id
	,er.status
	,er.database_id
	,er.start_time
	,er.total_elapsed_time
	,er.logical_reads
	,er.writes
	,substring(qt.text, (er.statement_start_offset/2)+1,
		((
			case er.statement_end_offset
				when -1 then datalength(qt.text)
				else er.statement_end_offset
			end - er.statement_start_offset)/2)+1) as [SQL],
	qp.query_plan, er.*
from
	sys.dm_exec_requests er with (nolock)
		cross apply sys.dm_exec_sql_text(er.sql_handle) qt
		cross apply sys.dm_exec_query_plan(er.plan_handle) qp
where
	er.session_id > 50 and /* Excluding system processes */
	er.session_id <> @@SPID
order by
	er.total_elapsed_time desc
option (recompile);
go




