/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 05. Deadlocks				            */
/*            Deadlock Due to Non-Optimized Queries (Session 2)             */
/****************************************************************************/

use [SQLServerInternals]
go

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

