/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 07. Lock Escalation				            */
/*               Lock Escalation and Nonoptimized Queries                   */
/****************************************************************************/

use SQLServerInternals
go

alter table Delivery.Orders set (lock_escalation = auto);
go

set transaction isolation level serializable
begin tran
    select OrderId, OrderDate, Amount
    from Delivery.Orders with (rowlock)
    where OrderNum = '1';

    select
        resource_type as [Resource Type]
        ,case resource_type
            when 'OBJECT' then 
			    object_name(resource_associated_entity_id,resource_database_id)
            when 'DATABASE' then 'DB'
            else
                (  select object_name(object_id, resource_database_id)
                        from sys.partitions
                        where hobt_id = resource_associated_entity_id )
        end as [Object]
        ,request_mode as [Mode]
        ,request_status as [Status]
    from sys.dm_tran_locks
    where request_session_id = @@SPID;
commit
