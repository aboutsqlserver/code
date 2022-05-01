/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 17. Lock Types                           */
/*                            Update (U) Locks                              */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/


--- Run SQL Profiler or Extended Events and monitor Lock Acquired/Lock 
--- Released events filtering by @@SPID

set transaction isolation level read uncommitted
begin tran
	-- Plan with Clustered Index Seek
	update Delivery.Orders
	set Reference = 'New Reference'
	where OrderId in (1000, 5000)
rollback
go

set transaction isolation level read uncommitted
begin tran
	-- Plan with Clustered Index Scan
	update Delivery.Orders 
	set Reference = 'New Reference'
	where OrderNum = '1000'
rollback
go
