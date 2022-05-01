/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 17. Lock Types                           */
/*                     (X) Lock Behavior (Session 2)                        */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

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
