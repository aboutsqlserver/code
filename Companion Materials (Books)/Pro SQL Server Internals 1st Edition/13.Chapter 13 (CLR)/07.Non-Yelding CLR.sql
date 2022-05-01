/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                              Chapter 13. CLR                             */
/*                            Non-Yelding CLR code                          */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*   That script uses objects created by "01.Object Creation.sql" script    */
/****************************************************************************/


exec dbo.EndlessLoop
go


/*** Run in another session ***/
select 
	er.session_id, ct.forced_yield_count,
	w.task_address, w.[state], w.last_wait_type, ct.state
from 
	sys.dm_clr_tasks ct with (nolock) join
		sys.dm_os_workers w with (nolock) on
		ct.sos_task_address = w.task_address
	join sys.dm_exec_requests er with (nolock) on
		w.task_address = er.task_address
where
	ct.type = 'E_TYPE_USER'
option (recompile)
