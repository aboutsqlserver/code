/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 17. Lock Types                           */
/*              Exclusive (X) and Intent Exclusive (IX) Locks               */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/


set transaction isolation level read uncommitted
begin tran
	update Delivery.Orders
	set Reference = 'New Reference'
	where OrderId = 100;

	select resource_type, resource_description,	
		request_type, request_mode, request_status 
	from sys.dm_tran_locks
	where request_session_id = @@spid;
rollback
go
