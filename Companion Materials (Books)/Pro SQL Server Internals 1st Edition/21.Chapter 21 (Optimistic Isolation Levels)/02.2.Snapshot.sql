/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                 Chapter 21. Optimistic Isolation Levels				    */
/*                      Snapshot Isolation (Session 2)                      */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/

/*** Test 1: Non-snapshot isolation levels ***/
-- (S) locks are blocked
select * from Delivery.Orders with (readcommitted) where OrderId = 1
go

/*** Test 2: Snapshot isolation levels ***/
-- No blocking
set transaction isolation level snapshot;
select * from Delivery.Orders where OrderId = 1
go


/*** Test 3: Snapshot isolation level and (X) locks ***/
-- (X) lock is blocked
set transaction isolation level snapshot;
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 2'
	where OrderId = 1
rollback
go

/*** Test 4: Snapshot isolation level and (U) locks ***/
-- (U) locks are not blocked
set transaction isolation level snapshot;
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 2'
	where OrderNum = '234'
rollback
go

