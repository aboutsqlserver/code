/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 20. Lock Escalations				            */
/*               Lock Escalation and Concurrency (Session 1)                */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

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
