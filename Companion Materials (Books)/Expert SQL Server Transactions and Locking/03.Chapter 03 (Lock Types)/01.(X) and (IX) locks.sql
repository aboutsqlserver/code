/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 03. Lock Types                           */
/*              Exclusive (X) and Intent Exclusive (IX) Locks               */
/****************************************************************************/

use [SQLServerInternals]
go

set transaction isolation level read uncommitted
begin tran
    update Delivery.Orders
    set Reference = 'New Reference'
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
commit

go
