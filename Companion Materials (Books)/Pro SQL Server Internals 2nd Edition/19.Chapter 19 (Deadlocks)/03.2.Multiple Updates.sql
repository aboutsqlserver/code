/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 19. Deadlocks				            */
/*                  Deadlock Due to Multiple Updates (Session 2)            */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

select top 10 ID, Value, ModTime
from dbo.Data
where ModTime > '2001-01-01'
order by ModTime, ID;