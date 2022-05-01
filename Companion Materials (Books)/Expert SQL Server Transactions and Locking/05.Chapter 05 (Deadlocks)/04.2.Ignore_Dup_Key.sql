/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 05. Deadlocks				            */
/*                       IGNORE_DUP_KEY deadlock (Session 2)                */
/****************************************************************************/

use [SqlServerInternals]
go

-- SESSION 2 CODE
set transaction isolation level read committed
begin tran
	insert into dbo.IgnoreDupKeysDeadlock(CICol,NCICol)
	values(12,12);

	select request_session_id, resource_type, resource_description
		,resource_associated_entity_id, request_mode, request_type, request_status
	from sys.dm_tran_locks
	where request_session_id = @@SPID;

	insert into dbo.IgnoreDupKeysDeadlock(CICol,NCICol)
	values(2,2);
commit;
go

