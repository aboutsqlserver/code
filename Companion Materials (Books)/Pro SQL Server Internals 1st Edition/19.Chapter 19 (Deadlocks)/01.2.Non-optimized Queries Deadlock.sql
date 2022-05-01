/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                           Chapter 19. Deadlocks				            */
/*            Deadlock Due to Non-Optimized Queries (Session 2)             */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/


set transaction isolation level read committed
begin tran
	update Delivery.Orders 
	set Amount = Amount * 1.1
	where OrderId = 1

	select count(*) as [Cnt]
	from Delivery.Orders	
	where CustomerId = 317
rollback
go

