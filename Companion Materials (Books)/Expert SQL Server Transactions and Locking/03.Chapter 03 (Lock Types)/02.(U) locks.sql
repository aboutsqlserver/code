/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 03. Lock Types                           */
/*                            Update (U) Locks                              */
/****************************************************************************/

use [SQLServerInternals]
go

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
