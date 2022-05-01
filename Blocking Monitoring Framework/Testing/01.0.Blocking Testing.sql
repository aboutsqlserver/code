/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                                 Testing                                  */
/*                    Testing Blocking Event Notification                   */
/****************************************************************************/


-- Testing approach:
-- 1. Test with queue activation disabled. 
--		Emulate blocking condition
--		See that event has been captured in SB queue
--		Call Activation Proc manually (in context of the caller) making sure that event has been processed
-- 2. Enable activation 
--		Emulate blocking condition
--		See that event has been processed and data is in the table


-- Initial Setup
use tempdb
go

create table dbo.Data
(
	ID int not null,
	Value int not null,

	constraint PK_Data
	primary key clustered(ID)
);
go

insert into dbo.Data
values(1,1),(2,2),(3,3),(4,4);
go

use DBA
go

-- Test case 1 (activation disabled)
-- Should return multiple events
select * from dbo.BlockedProcessNotificationQueue;
go

-- Should run without issues and populate data in the table
exec dbo.SB_BlockedProcessReport_Activation;
select * from dbo.BlockedProcessesInfo;
go

-- Enabling Activation
alter queue dbo.BlockedProcessNotificationQueue
with 
	status = ON,
	retention = OFF,
	activation
	(
		Status = ON,
		Procedure_Name = dbo.SB_BlockedProcessReport_Activation,
		MAX_QUEUE_READERS = 1, 
		EXECUTE AS OWNER
	);
go

-- Test 2: Repeat blocking condition and see that data is populated and WaitTime updated
select * from dbo.BlockedProcessesInfo;
go
