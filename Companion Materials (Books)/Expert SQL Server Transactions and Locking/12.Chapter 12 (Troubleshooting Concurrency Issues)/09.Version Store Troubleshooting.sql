/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 06. Optimistic Isolation Levels				    */
/*                                   DMVs                                   */
/****************************************************************************/

-- Getting tempdb space usage information including version store usage
select 
	sum(user_object_reserved_page_count) * 8 as [User Objects (KB)]
	,sum(internal_object_reserved_page_count) * 8 as [Internal Objects (KB)]
	,sum(version_store_reserved_page_count) * 8  as [Version Store (KB)]
	,sum(unallocated_extent_page_count) * 8 as [Free Space (KB)]
from
	tempdb.sys.dm_db_file_space_usage;
go

select 
	db_name(database_id) as [database]
	,database_id
	,sum(record_length_first_part_in_bytes + record_length_second_part_in_bytes) / 1024
		as [version store (KB)]
from sys.dm_tran_version_store 
group by database_id
go

-- SQL Server 2017 + 
select 
	db_name(database_id) as [database]
	,database_id
	,reserved_page_count
	,reserved_space_kb
from sys.dm_tran_version_store_space_usage 
go

select top 5
	at.transaction_id
	,at.elapsed_time_seconds
	,at.session_id
	,s.login_time
	,s.login_name
	,s.host_name
	,s.program_name
	,s.last_request_start_time
	,s.last_request_end_time
	,er.status
	,er.wait_type
	,er.blocking_session_id
	,er.wait_type
	,substring(
		st.text, 
		(er.statement_start_offset / 2) + 1,
		(case 
			er.statement_end_offset
		when -1 
			then datalength(st.text)
			else er.statement_end_offset
		end - er.statement_start_offset) / 2 + 1) 
				as [SQL]
from 
	sys.dm_tran_active_snapshot_database_transactions at
		join sys.dm_exec_sessions s on
			at.session_id = s.session_id
		left join sys.dm_exec_requests er on
			at.session_id = er.session_id
		outer apply
			sys.dm_exec_sql_text(er.sql_handle) st
order by 
	at.elapsed_time_seconds desc;
go
