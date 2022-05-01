/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 13: Utilizing In-Memory OLTP                     */
/*             03.Enforcing Referential Integrity Between                   */
/*         Disk-Based and Memory-Optimized Tables (Session 2)               */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

-- Session 2 code: Run in oarallel with the transaction that 
-- inserts ProductDescription row
delete from dbo.ProductsInMem where ProductId = 1; 