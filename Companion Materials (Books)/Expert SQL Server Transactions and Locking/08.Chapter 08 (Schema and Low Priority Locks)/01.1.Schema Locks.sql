/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 08. Schema Locks				            */
/*                     Schema Lock Demo (Session 1)                         */
/****************************************************************************/

use SQLServerInternals
go

/*** This script clears content of plan cache. Do not run on production server ***/
dbcc freeproccache
go

-- Run steps below 2 times. First time, sessions 2 and 3 will wait for 
-- schema-stability (Sch-S) locks. Second time (plans are cached), session 3
-- would wait for intent exclusive (IX) lock

-- STEP 1
begin tran
	alter table Delivery.Orders add Dummy int;

	-- Run Session 2 and Session 3 code

	select
		resource_type
		,request_type
		,request_mode
		,request_status										
	from sys.dm_tran_locks
	where 
		resource_associated_entity_id =
			object_id(N'Delivery.Orders');	
rollback
go