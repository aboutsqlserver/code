/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*           Chapter 08: Transaction Processing in In-Memory OLTP           */
/*                 04.SNAPSHOT Isolation Level (Session 2)                  */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

/*** Test 1 ***/
update dbo.HKData
set Col = -20 
where ID = 2
go

/*** Test 2 ***/
insert into dbo.HKData 
values(8,8)
go
