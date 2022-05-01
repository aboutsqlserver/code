/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 05. Deadlocks				            */
/*                  Deadlock Due to Multiple Updates (Session 2)            */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go

select top 10 ID, Value, ModTime
from dbo.Data
where ModTime > '2001-01-01'
order by ModTime, ID;