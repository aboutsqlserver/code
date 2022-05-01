/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
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
order by ModTime, ID