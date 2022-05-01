/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 03. Lock Types                           */
/*                     (X) Lock Behavior (Session 2)                        */
/****************************************************************************/

use SQLServerInternals
go


-- No (S) locks in READ UNCOMMITTED
select OrderId, Amount			
from Delivery.Orders with (nolock)
where OrderId between 94 and 96;
go

-- No (S) locks in READ UNCOMMITTED
set transaction isolation level read uncommitted
select OrderId, Amount			
from Delivery.Orders 
where OrderId between 94 and 96;
go

-- (S) locks and blocking in READ COMMITTED
-- It would work differently if READ_COMMITTED_SNAPSHOT database option is enabled
set transaction isolation level read committed
select OrderId, Amount			
from Delivery.Orders 
where OrderId between 94 and 96;
go
