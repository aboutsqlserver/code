/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 17. Lock Types                           */
/*              Exclusive (X) and Intent Exclusive (IX) Locks               */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/


set transaction isolation level read uncommitted
begin tran
	update Delivery.Orders
	set Reference = 'New Reference'
	where OrderId = 100

	select resource_type, resource_description,	
		request_type, request_mode, request_status 
	from sys.dm_tran_locks
	where request_session_id = @@spid
rollback
go
