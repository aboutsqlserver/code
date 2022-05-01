/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 07: In-Memory OLTP Concurrency Model                */
/*                    05.Write/Write Conflict (Session 1)                   */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go



/*** Test 1 ***/
-- Step 1
begin tran
	select ID, Col 
	from dbo.HKData with (snapshot)

	/*** Run Session 2 code ***/

	-- Step 2
	update dbo.HKData with (snapshot)
	set Col = -2
	where ID = 2
commit
go



/*** Test 2 ***/
-- Step 1
begin tran
	select ID, Col 
	from dbo.HKData with (snapshot)

	/*** Run Session 2 code ***/

	-- Step 2
	update dbo.HKData with (snapshot)
	set Col = -2
	where ID = 2
commit
go
