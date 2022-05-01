/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 07: In-Memory OLTP Concurrency Model                */
/*           06.PK Violation (Snapshot Validation) (Session 1)              */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

-- STEP 1
begin tran
	insert into dbo.HKData with (snapshot)  
		(ID, Col)
	values(100,100);

  /*** Run Session 2 code ***/
commit
