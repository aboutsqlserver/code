/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 08. Schema Locks				            */
/*                     Schema Lock Demo (Session 3)                         */
/****************************************************************************/

use SQLServerInternals
go

begin tran
	delete 
	from Delivery.Orders
	where OrderId = 1;
rollback
go
