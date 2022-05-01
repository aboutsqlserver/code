/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 17. Lock Types                           */
/*                      Shared (S) Locks (Session 2)                        */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/


-- Run Session 1 code without committing transaction
set transaction isolation level repeatable read
begin tran
	select 'Session 2:', OrderDate
	from Delivery.Orders 
	where OrderId = 500

	select request_session_id,
		resource_type, resource_description,	
		request_type, request_mode, request_status 
	from sys.dm_tran_locks
	where request_session_id in (@@spid,<SPID of Session 1>)
commit
go
