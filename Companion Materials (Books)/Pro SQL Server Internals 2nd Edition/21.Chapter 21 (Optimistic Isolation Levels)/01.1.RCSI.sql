/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 21. Optimistic Isolation Levels				    */
/*              Read Committed Snapshot Isolation (Session 1)               */
/****************************************************************************/


/****************************************************************************/
/*     Do not forget to disable RCSI isolation after script execution       */
/*                   (Code is at the end of the script)                     */
/****************************************************************************/


use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

/*** Enabling RCSI ***/
alter database SqlServerInternals 
set read_committed_snapshot on 
with rollback after 3 seconds;
go


-- Step 1:
begin tran
	update Delivery.Orders
	set Reference = 'Updated in Session 1'
	where OrderId = 1;

	-- Run code from Session 2 script
rollback
go

/*** Disabling RCSI ***/
alter database SqlServerInternals 
set read_committed_snapshot off
with rollback after 3 seconds;
go
