/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                   Chapter 27. System Troubleshooting                     */
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
option (recompile)

