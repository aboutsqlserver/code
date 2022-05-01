/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 17. Lock Types                           */
/*               Read Uncommitted - Dirty Reads (Session 2)                 */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/

select OrderId, Amount			
from Delivery.Orders with (nolock)
where OrderId between 94 and 96
go

set transaction isolation level read uncommitted

select OrderId, Amount			
from Delivery.Orders 
where OrderId between 94 and 96
go
