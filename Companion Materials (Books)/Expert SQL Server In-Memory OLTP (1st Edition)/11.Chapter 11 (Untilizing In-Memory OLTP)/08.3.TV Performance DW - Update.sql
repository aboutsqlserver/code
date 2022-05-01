/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*       08.Memory-Optimized Table Variable Performance (DW) - Update       */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

set statistics time on

update dw.FactSalesETLDisk set Quantity += 1;
update dw.FactSalesETLDisk set OrderNum += '1234567890';

update dw.FactSalesETLMem set Quantity += 1;
update dw.FactSalesETLMem set OrderNum += '1234567890';

set statistics time off

