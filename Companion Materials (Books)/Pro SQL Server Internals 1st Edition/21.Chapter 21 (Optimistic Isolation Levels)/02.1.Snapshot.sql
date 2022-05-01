/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                 Chapter 21. Optimistic Isolation Levels				    */
/*                      Snapshot Isolation (Session 1)                      */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/

/*** Enabling Snapshot ***/
alter database SqlServerInternals 
set allow_snapshot_isolation on 
go


-- Step 1:
-- Isolation level does not affect behavior
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 1'
	where OrderId = 1

	-- Run code from Session 2 script
rollback
go

/*** Enabling Snapshot ***/
alter database SqlServerInternals 
set allow_snapshot_isolation off
go
