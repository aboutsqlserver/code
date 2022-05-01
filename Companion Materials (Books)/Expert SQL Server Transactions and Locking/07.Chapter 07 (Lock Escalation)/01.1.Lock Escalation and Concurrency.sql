/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 07. Lock Escalation				            */
/*               Lock Escalation and Concurrency (Session 1)                */
/****************************************************************************/

use SQLServerInternals
go

/*** Test 1 Lock escalation is disabled ***/
-- In SQL Server 2005 use DBCC TRACEON(1211,@@SPID)
alter table Delivery.Orders set (lock_escalation = disable);
go

-- STEP 1
set transaction isolation level repeatable read
begin tran
	select count(*)
	from Delivery.Orders with (rowlock);
	
	select count(*) as [Lock Count]	
	from sys.dm_tran_locks 
	where request_session_id = @@SPID;

-- Run Session 2 Code
commit
go

/*** Test 1 Lock escalation is enabled ***/
-- In SQL Server 2005 use -- In SQL Server 2005 use DBCC TRACEOFF(1211,@@SPID)
alter table Delivery.Orders set (lock_escalation = auto);
go

-- STEP 1
set transaction isolation level repeatable read
begin tran
	select count(*)
	from Delivery.Orders with (rowlock);
	
	select count(*) as [Lock Count]	
	from sys.dm_tran_locks 
	where request_session_id = @@SPID;

-- Run Session 2 Code
commit
go
