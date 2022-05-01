/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 17. Lock Types                           */
/*       Shared (S) Locks Behavior based on Transaction Isolation Level     */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/


--- Run SQL Profiler or Extended Events and monitor Lock Acquired/Lock 
--- Released events filtering by @@SPID.

-- (S) Locks are released immediately after row was read
set transaction isolation level read committed
select OrderId, Amount							 
from Delivery.Orders					
where OrderId between 94 and 96
go

-- (S) Locks held till the end of transaction
set transaction isolation level repeatable read
select OrderId, Amount							 
from Delivery.Orders							
where OrderId between 94 and 96
go

-- Key Range (S) Locks held till the end of transaction
set transaction isolation level serializable
select OrderId, Amount							 
from Delivery.Orders							
where OrderId between 94 and 96
go
