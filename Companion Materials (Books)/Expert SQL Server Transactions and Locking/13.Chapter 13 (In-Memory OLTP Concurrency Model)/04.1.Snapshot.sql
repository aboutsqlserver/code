/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. In-Memory OLTP Concurrency Model               */
/*                 04.SNAPSHOT Isolation Level (Session 1)                  */
/****************************************************************************/

set nocount on
go

use SQLServerInternalsHK
go


/*** Test 1 ***/
-- Step 1
begin tran
	select ID, Col 
	from dbo.HKData with (Snapshot)

	/*** Run Session 2 code ***/

	-- Step 2
	select ID, Col 
	from dbo.HKData with (Snapshot)
commit
go

/*** Test 2 ***/
-- Step 1
begin tran
	select ID, Col 
	from dbo.HKData with (Snapshot)

	/*** Run Session 2 code ***/

	-- Step 2
	select ID, Col 
	from dbo.HKData with (Snapshot)
commit
go
