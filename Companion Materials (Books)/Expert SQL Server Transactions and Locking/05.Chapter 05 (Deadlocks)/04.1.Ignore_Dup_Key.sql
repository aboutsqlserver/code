/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 05. Deadlocks				            */
/*                       IGNORE_DUP_KEY deadlock (Session 1)                */
/****************************************************************************/

use SQLServerInternals
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'IgnoreDupKeysDeadlock') drop table dbo.IgnoreDupKeysDeadlock;
go

create table dbo.IgnoreDupKeysDeadlock
(
	CICol int not null,
	NCICol int not null
);

create unique clustered index IDX_IgnoreDupKeysDeadlock_CICol
on dbo.IgnoreDupKeysDeadlock(CICol);

create unique nonclustered index IDX_IgnoreDupKeysDeadlock_NCICol
on dbo.IgnoreDupKeysDeadlock(NCICol)
with (ignore_dup_key = on);

insert into dbo.IgnoreDupKeysDeadlock(CICol, NCICol)
values(0,0),(5,5),(10,10),(20,20);
go

-- SESSION 1 CODE
set transaction isolation level read uncommitted
begin tran
	/* STEP 1 */
	insert into dbo.IgnoreDupKeysDeadlock(CICol,NCICol)
	values(1,1);

	select request_session_id, resource_type, resource_description
		,resource_associated_entity_id, request_mode, request_type, request_status
	,'',''
	from sys.dm_tran_locks
	where request_session_id in( @@SPID, 57)
	and resource_type <> 'DATABASE';

	-- Run Session 2 Code

	/* STEP 2 */
	insert into dbo.IgnoreDupKeysDeadlock(CICol,NCICol)
	values(11,11);
commit;
go
