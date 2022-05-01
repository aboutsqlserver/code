/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 03. Lock Types                           */
/*                      Shared (S) Locks (Session 1)                        */
/****************************************************************************/

use SQLServerInternals
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

set transaction isolation level repeatable read
begin tran
	select 'Session 1:', OrderNum
	from Delivery.Orders 
	where OrderId = 500;

	-- Run Session 2 code
commit
go
