/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 19. Deadlocks				            */
/*            Deadlock Due to Non-Optimized Queries (Session 2)             */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/


set transaction isolation level read committed
begin tran
	update Delivery.Orders 
	set Amount = Amount * 1.1
	where OrderId = 1;

	select count(*) as [Cnt]
	from Delivery.Orders	
	where CustomerId = 317;
	-- Run Session 1 STEP 2 Code
rollback
go

