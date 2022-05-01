/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*           Chapter 08: Transaction Processing in In-Memory OLTP           */
/*              07.Referential Integrity Enforcement (Session21)            */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go


--Session 2 code
update dbo.Transactions with (snapshot) 
set Amount = 30
where TransactionId = 2;

