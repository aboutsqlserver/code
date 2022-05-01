/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 05. Deadlocks				            */
/*            Deadlock Due to Non-Optimized Queries (Session 1)             */
/****************************************************************************/

use [SQLServerInternals]
go

-- STEP 1
set transaction isolation level read committed

begin tran
	update Delivery.Orders 
	set Amount = Amount * 1.1
	where OrderId = 9999;

-- Run Session 2 code

-- STEP 2
	select count(*) as [Cnt]
	from Delivery.Orders	
	where CustomerId = 65;
rollback
go

