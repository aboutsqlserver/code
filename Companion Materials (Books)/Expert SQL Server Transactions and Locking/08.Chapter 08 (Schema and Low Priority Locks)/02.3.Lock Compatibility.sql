/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 08. Schema Locks				            */
/*                    Lock Compatibility (Session 3)                        */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

-- TEST 1: using READ COMMITTED
-- It may or may not be blocked.
select *
from Delivery.Orders with (readcommitted)
where OrderId = 1;
go

-- TEST 2: using REPEATABLE READ
-- It will be blocked
select *
from Delivery.Orders with (readcommitted)
where OrderId = 1;
go