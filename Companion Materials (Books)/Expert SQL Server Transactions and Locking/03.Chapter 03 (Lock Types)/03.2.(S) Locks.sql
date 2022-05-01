/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 03. Lock Types                           */
/*                      Shared (S) Locks (Session 2)                        */
/****************************************************************************/

use SQLServerInternals
go

-- Run Session 1 code without committing transaction
set transaction isolation level repeatable read
begin tran
	select 'Session 2:', OrderDate
	from Delivery.Orders 
	where OrderId = 500;

	select request_session_id,
		resource_type, resource_description,	
		request_type, request_mode, request_status 
	from sys.dm_tran_locks
	where request_session_id in (@@spid,<SPID of Session 1>);
commit
go
