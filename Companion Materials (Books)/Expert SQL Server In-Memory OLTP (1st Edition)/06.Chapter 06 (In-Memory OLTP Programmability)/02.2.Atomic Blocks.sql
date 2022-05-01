/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 06: In-Memory OLTP Programmability                 */
/*                       02.Atomic Blocks (Session 2)                       */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go


/*** Critical Errors ***/
-- Run together with Session 1 code
begin tran
	exec dbo.AtomicBlockDemo 1, 0, null, null

