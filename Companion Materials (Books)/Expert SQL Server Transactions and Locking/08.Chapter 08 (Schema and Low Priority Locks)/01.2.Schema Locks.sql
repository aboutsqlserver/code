/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 08. Schema Locks				            */
/*                     Schema Lock Demo (Session 2)                         */
/****************************************************************************/

use SQLServerInternals
go

select count(*)
from Delivery.Orders with (nolock);
go