/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 06. Optimistic Isolation Levels				    */
/*              Snapshot Isolation and Error 3960 (Session 2)               */
/****************************************************************************/

use SQLServerInternals
go

update Delivery.Orders
set Reference = convert(varchar(48),newid())
where OrderId = 1;
go

