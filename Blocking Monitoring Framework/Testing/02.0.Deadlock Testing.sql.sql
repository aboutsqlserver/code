/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                                 Testing                                  */
/*                       Testing Deadlocks Notification                     */
/****************************************************************************/


-- Testing approach:
-- 1. Test with queue activation disabled. 
--		Emulate deadlock condition
--		See that event has been captured in SB queue
--		Call Activation Proc manually (in context of the caller) making sure that event has been processed
-- 2. Enable activation 
--		Emulate deadlok condition
--		See that event has been processed and data is in the table

-- The script uses tempdb.dbo.Data table created by 01.0.Blocking Testing.sql script

use DBA
go

-- Test case 1 (activation disabled)
select * from dbo.DeadlockNotificationQueue;
go

-- Should run without issues and populate data in the table
exec dbo.SB_DeadlockEvent_Activation;;
select * from dbo.Deadlocks;
select * from dbo.DeadlockProcesses;
go

-- Enabling Activation
alter queue dbo.DeadlockNotificationQueue
with 
	status = ON,
	retention = OFF,
	activation
	(
		Status = ON,
		Procedure_Name = dbo.SB_DeadlockEvent_Activation,
		max_queue_readers = 1, 
		execute as owner
	);
go

-- Test 2: Repeat blocking condition and see that data is populated and WaitTime updated
select * from dbo.Deadlocks;
select * from dbo.DeadlockProcesses;
go