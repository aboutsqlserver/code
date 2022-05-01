/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 06. Optimistic Isolation Levels				    */
/*              Read Committed Snapshot Isolation (Session 1)               */
/****************************************************************************/

use SQLServerInternals
go

/*** Enabling RCSI ***/
alter database SQLServerInternals 
set read_committed_snapshot on 
with rollback after 3 seconds;
go


-- Step 1:
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 1'
	where OrderId = 1;

	-- Run code from Session 2 script
rollback
go

/*** Disabling RCSI ***/
alter database SQLServerInternals 
set read_committed_snapshot off
with rollback after 3 seconds;
go
