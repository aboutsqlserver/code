/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 12: Deployment and Management                    */
/*                   04.Monitoring Active Transactions                      */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

select top 5
	t.session_id
	,t.xtp_transaction_id
	,t.transaction_id
	,t.begin_tsn
	,t.end_tsn
	,t.state_desc
	,t.result_desc
	,substring(
		qt.text
		,er.statement_start_offset / 2 + 1
		,(case er.statement_end_offset
			when -1 then datalength(qt.text)
			else er.statement_end_offset
		end - er.statement_start_offset
	) / 2 +1) as SQL
from 
   sys.dm_db_xtp_transactions t 
      left join sys.dm_exec_requests er on
         t.session_id = er.session_id
      outer apply 
         sys.dm_exec_sql_text(er.sql_handle) qt
where
   t.state in (0,3) /* ACTIVE/VALIDATING */
order by 
   t.begin_tsn
go