/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 06. Optimistic Isolation Levels				    */
/*              Snapshot Isolation and Error 3960 (Session 1)               */
/****************************************************************************/

use SQLServerInternals
go

/*** Enabling snapshot ***/
alter database SQLServerInternals 
set allow_snapshot_isolation on; 
go


-- Step 1 -- starting transaction
set transaction isolation level snapshot
begin tran
	select * 
	from Delivery.Orders 
	where OrderId = 1000;

	-- Run Session 2 code
	
	-- Step 2
	update Delivery.Orders
	set Reference = convert(varchar(48),newid())
	where OrderId = 1;
commit
go


/*** Disabling Snapshot ***/
alter database SQLServerInternals 
set allow_snapshot_isolation off;
go
