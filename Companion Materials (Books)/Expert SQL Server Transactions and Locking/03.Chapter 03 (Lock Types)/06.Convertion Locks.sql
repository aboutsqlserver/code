/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 03. Lock Types                           */
/*							   Convertion Locks								*/
/****************************************************************************/

use SQLServerInternals
go

begin tran
	select top 10 OrderId, Amount
	from Delivery.Orders with (repeatableread tablock)
	order by OrderId;
	
    select 
        l.resource_type
        ,case 
			when l.resource_type = 'OBJECT'
			then object_name(l.resource_associated_entity_id, l.resource_database_id)
			else ''
		end as [table]
        ,l.resource_description	
        ,l.request_type
        ,l.request_mode
        ,l.request_status 
     from 
        sys.dm_tran_locks l 
     where 
        l.request_session_id = @@spid;

	update Delivery.Orders
	set Amount *= 0.95
	where OrderId = 100;

	select 
        l.resource_type
        ,case 
			when l.resource_type = 'OBJECT'
			then object_name(l.resource_associated_entity_id, l.resource_database_id)
			else ''
		end as [table]
        ,l.resource_description	
        ,l.request_type
        ,l.request_mode
        ,l.request_status 
     from 
        sys.dm_tran_locks l 
     where 
        l.request_session_id = @@spid;
rollback;
go

