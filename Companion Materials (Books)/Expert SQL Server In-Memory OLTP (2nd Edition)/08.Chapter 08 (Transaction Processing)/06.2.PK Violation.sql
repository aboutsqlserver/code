/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*           Chapter 08: Transaction Processing in In-Memory OLTP           */
/*            06.PK Violation (Snapshot Validation) (Session 2)             */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

begin tran
	insert into dbo.HKData with (snapshot)  
		(ID, Col)
	values(100,100);

	/*** Commit Tran in Session 1 ***/
commit
