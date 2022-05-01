/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                 Chapter 21. Optimistic Isolation Levels				    */
/*              Read Committed Snapshot Isolation (Session 2)               */
/****************************************************************************/


set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/

/*** Test 1: RCSI and Readers ***/
-- Session reads old version of the row
select * from Delivery.Orders where OrderId = 1
go

/*** Test 2 RCSI and Writers (X) locks ***/
-- (X) lock is blocked
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 2'
	where OrderId = 1
rollback
go

/*** Test 3 RCSI and Writers (U) locks ***/
-- (U) lock is blocked
-- Step 1:
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 2'
	where OrderNum = '23'
rollback
go

