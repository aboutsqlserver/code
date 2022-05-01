/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. In-Memory OLTP Concurrency Model               */
/*              07.Referential Integrity Enforcement (Session21)            */
/****************************************************************************/

set nocount on
go


-- Requires SQL Server 2016+

use SQLServerInternalsHK
go


--Session 2 code
update dbo.Transactions with (snapshot) 
set Amount = 30
where TransactionId = 2;

