/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 04.Blocking In The System                    */
/*           Obtaining SQL Text and Execution Plan by sql_handle            */
/****************************************************************************/

declare	
	@H varbinary(max) = 
		/* Insert sql_handle from the top line of the execution stack */
	,@S int =  
		/* Insert stmtStart from the top line of the execution stack */
	,@E int = 
		/* Insert stmtEnd from the top line of the execution stack */

select	
	substring(
		qt.text, 
	 	(qs.statement_start_offset / 2) + 1,
		((case qs.statement_end_offset
			when -1 then datalength(qt.text)
			else qs.statement_end_offset
		end - qs.statement_start_offset) / 2) + 1
	) as sql
	,qp.query_plan
	,qs.creation_time
	,qs.last_execution_time
from	
	sys.dm_exec_query_stats qs with (nolock)
		cross apply sys.dm_exec_sql_text(qs.sql_handle) qt
		cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
where	
	qs.sql_handle = @H and 
	qs.statement_start_offset = @S
	and qs.statement_end_offset = @E 
option	(recompile);  
