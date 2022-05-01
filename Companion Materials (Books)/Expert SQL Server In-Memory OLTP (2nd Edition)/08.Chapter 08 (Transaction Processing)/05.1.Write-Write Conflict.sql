/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*           Chapter 08: Transaction Processing in In-Memory OLTP           */
/*                    05.Write/Write Conflict (Session 1)                   */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
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
