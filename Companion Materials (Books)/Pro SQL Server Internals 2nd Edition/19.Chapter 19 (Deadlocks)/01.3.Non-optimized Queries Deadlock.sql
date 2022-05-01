/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 19. Deadlocks				            */
/*        Deadlock Due to Non-Optimized Queries (Monitoring Query)          */
/****************************************************************************/

/*** Run at time when both sessions are blocked ***/

select
	tl.request_session_id as [SPID]
	,tl.resource_type as [Resouce Type]
	,tl.resource_description as [Resource]
	,tl.request_mode as [Mode]
	,tl.request_status as [Status]
	,wt.blocking_session_id as [Blocked By]
from
	sys.dm_tran_locks tl with (nolock) left outer join sys.dm_os_waiting_tasks wt with (nolock) on
		tl.lock_owner_address = wt.resource_address and tl.request_status = 'WAIT'
where
	tl.request_session_id <> @@SPID 
order by
	tl.request_session_id
option (recompile);

