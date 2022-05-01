/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 04.Blocking In The System                    */
/*       Obtaining SQL Text and Execution Plan from sys.dm_exec_requests    */
/****************************************************************************/

declare	
	@SPID int = <insert session id here>

select	
	er.session_id
	,er.start_time
	,er.status
	,er.wait_type
	,er.last_wait_type
	,er.wait_time
	,substring(
		qt.text, 
	 	(er.statement_start_offset / 2) + 1,
		((case er.statement_end_offset
			when -1 then datalength(qt.text)
			else er.statement_end_offset
		end - er.statement_start_offset) / 2) + 1
	) as sql
	,qp.query_plan
from	
	sys.dm_exec_requests er with (nolock)
		cross apply sys.dm_exec_sql_text(er.sql_handle) qt
		cross apply sys.dm_exec_query_plan(er.plan_handle) qp
where	
	er.session_id = @SPID
option	(recompile);  
