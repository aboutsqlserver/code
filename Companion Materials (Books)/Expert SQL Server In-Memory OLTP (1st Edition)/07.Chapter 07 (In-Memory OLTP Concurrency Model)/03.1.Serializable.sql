/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 07: In-Memory OLTP Concurrency Model                */
/*               03.SERIALIZABLE Isolation Level (Session 1)                */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

/*** Test 1 ***/
-- Step 1
begin tran
	select ID, Col 
	from dbo.HKData with (serializable)

	/*** Run Session 2 code ***/

	-- Step 2
	select ID, Col 
	from dbo.HKData with (serializable)
commit
go

/*** Test 2 ***/
-- Step 1
begin tran
	select ID, Col 
	from dbo.HKData with (serializable)

	/*** Run Session 2 code ***/

	-- Step 2
	select ID, Col 
	from dbo.HKData with (serializable)
commit
go
