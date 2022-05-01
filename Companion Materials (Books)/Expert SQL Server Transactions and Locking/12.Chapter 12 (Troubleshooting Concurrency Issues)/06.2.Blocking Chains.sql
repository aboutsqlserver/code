/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 12. Troubleshooting Concurrency Issues              */
/*                         Blocking Chain (Session 2)                       */
/****************************************************************************/

use SQLServerInternals
go

begin tran
	update Delivery.Orders
	set Pieces += 1 
	where OrderId = 1;

	select count(*) 
	from Delivery.Customers with (readcommitted);

rollback