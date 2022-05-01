/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 09. Lock Partitioning				        */
/*                  Lock Partitioning Deadlock (Session 1)                  */
/****************************************************************************/

-- You need to have 16 or more schedulers for lock partitioning to be enabled

-- You can artificially change number of cores with undocumented startup flag -P[N] 
-- [N] is number of cores. DO NOT DO THIS IN PRODUCTION!

use SQLServerInternals
go

-- The condition when scheduler changes is hard to emulate. It is better
-- to run some artificial load on the system 

select scheduler_id from sys.dm_exec_requests s where session_id = @@SPID;
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
	where request_session_id in (@@SPID);

	-- Run Session 2 code

	-- You may consider to wait until new scheduler is assigned with ID < than before
	select scheduler_id from sys.dm_exec_requests s where session_id = @@SPID;

	-- Step 2: May or may not trigger the deadlock
	update Delivery.Orders
	set Pieces += 1
	where OrderId = 10;

	-- Run session 2 code
	select 
		request_session_id
		,resource_type
		,resource_lock_partition
		,request_mode 
		,request_status
	from sys.dm_tran_locks
	where request_session_id in (@@SPID, 68) -- SPID of the second session
	order by request_session_id

	-- Step 3 will lead to deadlock
	select count(*)
	from Delivery.Orders with (tablock)
rollback
