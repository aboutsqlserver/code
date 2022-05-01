/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 06. Optimistic Isolation Levels				    */
/*                      Snapshot Isolation (Session 2)                      */
/****************************************************************************/

use SQLServerInternals
go

/*** Test 1: Non-snapshot isolation levels ***/
-- (S) locks are blocked
select * from Delivery.Orders with (readcommitted) where OrderId = 1;
go

/*** Test 2: Snapshot isolation levels ***/
-- No blocking
set transaction isolation level snapshot;
select * from Delivery.Orders where OrderId = 1;
go


/*** Test 3: Snapshot isolation level and (X) locks ***/
-- (X) lock is blocked
set transaction isolation level snapshot;
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 2'
	where OrderId = 1;
rollback
go

/*** Test 4: Snapshot isolation level and (U) locks ***/
-- (U) locks are not blocked
set transaction isolation level snapshot;
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 2'
	where OrderNum = '234';
rollback
go

