/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 17. Lock Types                           */
/*         Transaction Isolation Levels and Shared (S) Locks Behavior       */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/


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
