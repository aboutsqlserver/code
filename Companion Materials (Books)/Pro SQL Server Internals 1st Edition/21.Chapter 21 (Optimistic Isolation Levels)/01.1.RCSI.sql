/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                 Chapter 21. Optimistic Isolation Levels				    */
/*              Read Committed Snapshot Isolation (Session 1)               */
/****************************************************************************/


/****************************************************************************/
/*     Do not forget to disable RCSI isolation after script execution       */
/*                   (Code is at the end of the script)                     */
/****************************************************************************/


set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/

/*** Enabling RCSI ***/
alter database SqlServerInternals 
set read_committed_snapshot on 
with rollback after 3 seconds
go


-- Step 1:
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 1'
	where OrderId = 1

	-- Run code from Session 2 script
rollback
go

/*** Disabling RCSI ***/
alter database SqlServerInternals 
set read_committed_snapshot off
with rollback after 3 seconds
go
