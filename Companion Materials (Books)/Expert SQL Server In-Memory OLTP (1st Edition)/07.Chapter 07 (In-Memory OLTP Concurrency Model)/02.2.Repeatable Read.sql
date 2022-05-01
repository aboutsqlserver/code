/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 07: In-Memory OLTP Concurrency Model                */
/*             02.REPEATABLE READ Isolation Level (Session 2)               */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

/*** Test 1 ***/
update dbo.HKData
set Col = -2 
where ID = 2
go

/*** Test 2 ***/
insert into dbo.HKData 
values(10,10)
go