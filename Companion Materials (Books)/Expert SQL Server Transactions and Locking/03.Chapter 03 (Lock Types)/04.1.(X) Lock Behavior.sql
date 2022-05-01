/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 03. Lock Types                           */
/*                     (X) Lock Behavior (Session 1)                        */
/****************************************************************************/

use SQLServerInternals
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

-- (X) lock behavior does not depend on transaction isolation level
-- Notice that we are using READ UNCOMMITTED here
set transaction isolation level read uncommitted
begin tran
	delete from Delivery.Orders 
	where OrderId = 95;

	-- Run Session 2 code
rollback
go
