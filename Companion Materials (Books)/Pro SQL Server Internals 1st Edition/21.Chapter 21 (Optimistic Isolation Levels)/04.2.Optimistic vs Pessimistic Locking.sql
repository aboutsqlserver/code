/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                 Chapter 21. Optimistic Isolation Levels				    */
/*             Optimistic vs. Pessimistic Locking (Session 2)               */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/*** Test 1: Pessimistic Locking ***/
-- Session would be blocked until 1st session commits
set transaction isolation level read committed
begin tran
	update dbo.Colors
	set Color = 'Black'
	where Color = 'White'
commit
go



/*** Test 2: Optimistic Locking ***/

-- Step 1 -- starting transaction
set transaction isolation level snapshot
begin tran
	update dbo.Colors
	set Color = 'Black'
	where Color = 'White'
commit
go

