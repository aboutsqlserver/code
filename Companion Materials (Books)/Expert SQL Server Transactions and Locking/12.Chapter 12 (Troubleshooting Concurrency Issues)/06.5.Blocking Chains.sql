/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 12. Troubleshooting Concurrency Issues              */
/*                           Blocking Chain - DMVs                          */
/****************************************************************************/

use SQLServerInternals
go

select session_id, blocking_session_id, wait_type, resource_description
from sys.dm_os_waiting_tasks with (nolock)
where session_id > 50
order by session_id;

select session_id, status, blocking_session_id, wait_type, wait_resource
from sys.dm_exec_requests with (nolock)
where session_id > 50 and session_id < 64
order by session_id;

-- If BMFramework is enabled
select top 100 *
from DBA.dbo.BlockedProcessesInfo;


