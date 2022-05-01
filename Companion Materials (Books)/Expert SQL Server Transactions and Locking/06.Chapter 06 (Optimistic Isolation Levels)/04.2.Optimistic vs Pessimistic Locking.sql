/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 06. Optimistic Isolation Levels				    */
/*             Optimistic vs. Pessimistic Locking (Session 2)               */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go

/*** Test 1: Pessimistic Locking ***/
-- Session would be blocked until 1st session commits
set transaction isolation level read committed
begin tran
	update dbo.Colors
	set Color = 'Black'
	where Color = 'White';
commit
go



/*** Test 2: Optimistic Locking ***/

-- Step 1 -- starting transaction
set transaction isolation level snapshot
begin tran
	update dbo.Colors
	set Color = 'Black'
	where Color = 'White';
commit
go

