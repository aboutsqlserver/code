/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
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

