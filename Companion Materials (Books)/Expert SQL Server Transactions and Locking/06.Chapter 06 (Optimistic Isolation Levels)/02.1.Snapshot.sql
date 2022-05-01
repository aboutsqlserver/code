/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 06. Optimistic Isolation Levels				    */
/*                      Snapshot Isolation (Session 1)                      */
/****************************************************************************/

use SQLServerInternals
go

/*** Enabling Snapshot ***/
alter database SQLServerInternals 
set allow_snapshot_isolation on; 
go


-- Step 1:
-- Isolation level does not affect behavior
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 1'
	where OrderId = 1;

	-- Run code from Session 2 script
rollback
go

/*** Disabling Snapshot ***/
alter database SQLServerInternals 
set allow_snapshot_isolation off;
go
