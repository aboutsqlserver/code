/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                       Chapter 23. Schema Locks				            */
/*                    Lock Compatibility (Session 3)                        */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/

-- TEST 1: using READ COMMITTED
-- It may or may not be blocked.
select *
from Delivery.Orders with (readcommitted)
where OrderId = 1
go

-- TEST 2: using REPEATABLE READ
-- It will be blocked
select *
from Delivery.Orders with (readcommitted)
where OrderId = 1
go