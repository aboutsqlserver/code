/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 09: In-Memory OLTP Programmability                 */
/*                       02.Atomic Blocks (Session 2)                       */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go


/*** Critical Errors ***/
-- Run together with Session 1 code
begin tran
	exec dbo.AtomicBlockDemo 1, 0, null, null

