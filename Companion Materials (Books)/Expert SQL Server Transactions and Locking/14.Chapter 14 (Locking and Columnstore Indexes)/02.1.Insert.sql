/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 14. Locking and Columnstore Indexes                */
/*                      Append Workload (Session 1)                         */
/****************************************************************************/

use SQLServerInternals
go

-- Test 1: Locking during insert
begin tran
	insert into dbo.Test(ID, Col)
	values(-1,-1);

	-- You can run Session 2 insert in parallel while transaction is active
	-- and see that there is no blocking

	select 
		resource_type, resource_description
		,request_mode, request_status
		,resource_associated_entity_id
	from sys.dm_tran_locks 
	where 
		request_session_id = @@SPID 
		--and resource_subtype = '' and resource_type <> 'OBJECT'
rollback
go
