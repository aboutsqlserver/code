/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 21. Optimistic Isolation Levels				    */
/*                      Snapshot Isolation (Session 1)                      */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

/*** Enabling Snapshot ***/
alter database SqlServerInternals 
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

/*** Enabling Snapshot ***/
alter database SqlServerInternals 
set allow_snapshot_isolation off;
go
