/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 09. Lock Partitioning				        */
/*                 Analyzing Lock Partitioning (Session 1)                  */
/****************************************************************************/

-- You need to have 16 or more schedulers for lock partitioning to be enabled

-- You can artificially change number of cores with undocumented startup flag -P[N] 
-- [N] is number of cores. DO NOT DO THIS IN PRODUCTION!

use SQLServerInternals
go

select scheduler_id from sys.dm_exec_requests where session_id = @@SPID;

select * from sys.dm_os_schedulers;
go

-- Step 1
begin tran
    select * 
    from Delivery.Orders with (repeatableread)
	where OrderId = 100;

	select 
		request_session_id
		,resource_type
		,resource_lock_partition
		,request_mode
		,request_status
	from sys.dm_tran_locks
	where request_session_id in (@@SPID)

	-- Run session 2 code
	select 
		request_session_id
		,resource_type
		,resource_lock_partition
		,request_mode 
		,request_status
	from sys.dm_tran_locks
	where request_session_id in (@@SPID, 53) -- SPID of the second session
	order by request_session_id
rollback
