/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                Chapter 18. Troubleshooting Blocking Issues               */
/*                         Data Management Views                            */
/****************************************************************************/

use [SqlServerInternals]
go

-- All active requests to Lock Manager
select * from sys.dm_tran_locks;
go

-- More details about locking
select
	TL1.resource_type as [Resource Type]
	,db_name(TL1.resource_database_id) as [DB Name]
	,case TL1.resource_type
		when 'OBJECT' then 
			object_name(TL1.resource_associated_entity_id
				,TL1.resource_database_id)
		when 'DATABASE' then
			'DB'
		else
			case
				when TL1.resource_database_id = db_id() 
				then
				(
					select object_name(object_id
							,TL1.resource_database_id)
					from sys.partitions
					where hobt_id =
						TL1.resource_associated_entity_id
				)
				else
					'(Run under DB context)'
			end
	end as [Object]
	,TL1.resource_description as [Resource]
	,TL1.request_session_id as [Session]
	,TL1.request_mode as [Mode]
	,TL1.request_status as [Status]
	,WT.wait_duration_ms as [Wait (ms)]
	,QueryInfo.sql
	,QueryInfo.query_plan
from
	sys.dm_tran_locks TL1 with (nolock) 
		left outer join sys.dm_os_waiting_tasks WT with (nolock) on
			TL1.lock_owner_address = WT.resource_address 
			and TL1.request_status = 'WAIT'
	outer apply
	(
		select
			substring(
				S.Text, 
				(ER.statement_start_offset / 2) + 1,
				((
					case 
						ER.statement_end_offset
					when -1 
						then datalength(S.text)
						else ER.statement_end_offset
					end - ER.statement_start_offset) / 2) + 1
			) as sql,
			qp.query_plan
		from 
			sys.dm_exec_requests ER with (nolock)
				cross apply sys.dm_exec_sql_text(ER.sql_handle) S
				outer apply sys.dm_exec_query_plan(er.plan_handle) qp
		where
			TL1.request_session_id = ER.session_id
	)  QueryInfo
where
	TL1.request_session_id <> @@spid
order by
	TL1.request_session_id
option (recompile);
go


-- Filtering out blocking and blocked sessions
select
	TL1.resource_type as [Resource Type]
	,db_name(TL1.resource_database_id) as [DB Name]
	,case TL1.resource_type
		when 'OBJECT' then 
			object_name(TL1.resource_associated_entity_id
				,TL1.resource_database_id)
		when 'DATABASE' then
			'DB'
		else
			case
				when TL1.resource_database_id = db_id() 
				then
				(
					select object_name(object_id
							,TL1.resource_database_id)
					from sys.partitions
					where hobt_id =
						TL1.resource_associated_entity_id
				)
				else
					'(Run under DB context)'
			end
	end as [Object]
	,TL1.resource_description as [Resource]
	,TL1.request_session_id as [Session]
	,TL1.request_mode as [Mode]
	,TL1.request_status as [Status]
	,WT.wait_duration_ms as [Wait (ms)]
	,QueryInfo.sql
	,QueryInfo.query_plan								
from
	sys.dm_tran_locks TL1 with (nolock) 
		join sys.dm_tran_locks TL2 with (nolock) on
			TL1.resource_associated_entity_id =
				TL2.resource_associated_entity_id
		left outer join sys.dm_os_waiting_tasks WT with (nolock) on
			TL1.lock_owner_address = WT.resource_address and 
			TL1.request_status = 'WAIT'
	outer apply
	(
		select
			substring(
				S.Text, 
				(ER.statement_start_offset / 2) + 1,
				((
					case 
						ER.statement_end_offset
					when -1 
						then datalength(S.text)
						else ER.statement_end_offset
					end - ER.statement_start_offset) / 2) + 1
			) as sql,
			qp.query_plan
		from 
			sys.dm_exec_requests ER with (nolock)
				cross apply sys.dm_exec_sql_text(ER.sql_handle) S
				outer apply sys.dm_exec_query_plan(er.plan_handle) qp
		where
			TL1.request_session_id = ER.session_id
	)  QueryInfo
where
	TL1.request_status <> TL2.request_status and
	(
		TL1.resource_description = TL2.resource_description OR
		(TL1.resource_description is null and 
			TL2.resource_description is null)
	)
option (recompile);
go