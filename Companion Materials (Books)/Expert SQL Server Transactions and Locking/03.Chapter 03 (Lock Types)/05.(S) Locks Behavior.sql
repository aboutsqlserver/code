/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 03. Lock Types                           */
/*         Transaction Isolation Levels and Shared (S) Locks Behavior       */
/****************************************************************************/

use SQLServerInternals
go


--- Run SQL Profiler or Extended Events and monitor Lock Acquired/Lock 
--- Released events filtering by @@SPID.

-- (S) Locks are released immediately after row was read
set transaction isolation level read committed
select OrderId, Amount							 
from Delivery.Orders					
where OrderId between 94 and 96;
go

-- (S) Locks held till the end of transaction
set transaction isolation level repeatable read
select OrderId, Amount							 
from Delivery.Orders							
where OrderId between 94 and 96;
go

-- Key Range (S) Locks held till the end of transaction
set transaction isolation level serializable
select OrderId, Amount							 
from Delivery.Orders							
where OrderId between 94 and 96;
go
