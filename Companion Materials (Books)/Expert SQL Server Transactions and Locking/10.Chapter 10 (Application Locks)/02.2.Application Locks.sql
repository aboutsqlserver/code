/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 10. Application Locks                       */
/*                      Application Locks (Session 2)                       */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go

-- Session 2 code
exec dbo.LoadRawData @PacketSize = 50;
go
