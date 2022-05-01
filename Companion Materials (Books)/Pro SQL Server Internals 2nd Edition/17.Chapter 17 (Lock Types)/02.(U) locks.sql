/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 17. Lock Types                           */
/*                            Update (U) Locks                              */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/


--- Run SQL Profiler or Extended Events and monitor Lock Acquired/Lock 
--- Released events filtering by @@SPID

set transaction isolation level read uncommitted
begin tran
	-- Plan with Clustered Index Seek
	update Delivery.Orders
	set Reference = 'New Reference'
	where OrderId in (1000, 5000);
rollback
go

set transaction isolation level read uncommitted
begin tran
	-- Plan with Clustered Index Scan
	update Delivery.Orders 
	set Reference = 'New Reference'
	where OrderNum = '1000';
rollback
go
