/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                            Chapter 14. CLR                               */
/*                            Non-Yelding CLR code                          */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*   That script uses objects created by "01.Object Creation.sql" script    */
/****************************************************************************/

exec dbo.EndlessLoop;
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
option (recompile);
