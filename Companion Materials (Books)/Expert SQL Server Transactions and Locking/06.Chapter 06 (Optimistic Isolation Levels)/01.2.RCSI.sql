/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 06. Optimistic Isolation Levels				    */
/*              Read Committed Snapshot Isolation (Session 2)               */
/****************************************************************************/


use SQLServerInternals
go

/*** Test 1: RCSI and Readers ***/
-- Session reads old version of the row
select * from Delivery.Orders where OrderId = 1;
go

/*** Test 2 RCSI and Writers (X) locks ***/
-- (X) lock is blocked
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 2'
	where OrderId = 1;
rollback
go

/*** Test 3 RCSI and Writers (U) locks ***/
-- (U) lock is blocked
-- Step 1:
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 2'
	where OrderNum = '23';
rollback
go

