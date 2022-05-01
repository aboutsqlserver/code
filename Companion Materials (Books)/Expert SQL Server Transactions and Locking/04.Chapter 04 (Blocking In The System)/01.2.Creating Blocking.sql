/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 04.Blocking In The System                    */
/*                    Create Blocking Condition (Session 2)                 */
/****************************************************************************/

use SQLServerInternals
go

set transaction isolation level read committed
select OrderId, Amount
from Delivery.Orders 
where OrderNum = '1000';