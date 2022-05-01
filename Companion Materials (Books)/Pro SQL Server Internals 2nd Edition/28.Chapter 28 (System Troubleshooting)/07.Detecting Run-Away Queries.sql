/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 28. System Troubleshooting                     */
/*                       Detecting Run-Away Queries                         */
/****************************************************************************/

select top 10
	er.session_id
	,er.start_time
	,er.cpu_time
	,er.status
	,er.command
	,er.blocking_session_id
	,er.wait_time
	,er.wait_type
	,er.last_wait_type
	,er.logical_reads
	,substring(qt.text, (er.statement_start_offset/2)+1,
		((
			case er.statement_end_offset
				when -1 then datalength(qt.text)
				else er.statement_end_offset
			end - er.statement_start_offset)/2)+1) as SQL

from 
	sys.dm_exec_requests er with (nolock)
		cross apply sys.dm_exec_sql_text(er.sql_handle) qt
order by cpu_time desc
option (recompile);

/*** Obtaining information about the session ***/
select
	ec.session_id
	,db_name(s.database_id) as [Current DB] -- SQL Server 2012+
	,s.login_time 
	,s.host_name
	,s.program_name
	,s.login_name
	,s.original_login_name
	,s.cpu_time
	,s.last_request_start_time
	,s.reads
	,s.writes
	,ec.connect_time
	,qt.text as [SQL]
from 
	sys.dm_exec_connections ec with (nolock) 
		join sys.dm_exec_sessions s with (nolock) on
			ec.session_id = s.session_id
		cross apply 
			sys.dm_exec_sql_text(ec.most_recent_sql_handle) qt
where
	ec.session_id = 51 -- session id of the session
option (recompile);
go