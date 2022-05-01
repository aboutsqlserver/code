/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 06. Optimistic Isolation Levels				    */
/*              Optimistic Isolation Level and Fragmentation                */
/****************************************************************************/

set nocount on
go

alter database SQLServerInternals 
set read_committed_snapshot off
with rollback immediate;
go

alter database SQLServerInternals 
set allow_snapshot_isolation off;
go

use SQLServerInternals
go

alter index PK_Orders on Delivery.Orders rebuild
with (fillfactor = 100);
go

select 
	   alloc_unit_type_desc as [alloc_unit],
       index_level, 
       page_count, 
       convert(decimal(5,2),avg_page_space_used_in_percent)
			as [space_used], 
       convert(decimal(5,2),avg_fragmentation_in_percent)
			as [frag %],
       min_record_size_in_bytes as [min_size],
       max_record_size_in_bytes as [max_size],
       avg_record_size_in_bytes as [avg_size]
from sys.dm_db_index_physical_stats(db_id(),object_id(N'Delivery.Orders'),1,null,'DETAILED');
go 

begin tran
	delete from Delivery.Orders where OrderId % 2 = 0;
	-- Update Delivery.Orders set Pieces += 1;

	select 
	   alloc_unit_type_desc as [alloc_unit],
       index_level, 
       page_count, 
       convert(decimal(5,2),avg_page_space_used_in_percent)
			as [space_used], 
       convert(decimal(5,2),avg_fragmentation_in_percent)
			as [frag %],
       min_record_size_in_bytes as [min_size],
       max_record_size_in_bytes as [max_size],
       avg_record_size_in_bytes as [avg_size]
	from sys.dm_db_index_physical_stats(db_id(),object_id(N'Delivery.Orders'),1,null,'DETAILED');
rollback
go 


alter database SQLServerInternals 
set read_committed_snapshot on
with rollback immediate;
go

set transaction isolation level read uncommitted
begin tran
	delete from Delivery.Orders where OrderId % 2 = 0;
	-- Update Delivery.Orders set Pieces += 1;
rollback	 
go

select 
	   alloc_unit_type_desc as [alloc_unit],
       index_level, 
       page_count, 
       convert(decimal(5,2),avg_page_space_used_in_percent)
			as [space_used], 
       convert(decimal(5,2),avg_fragmentation_in_percent)
			as [frag %],
       min_record_size_in_bytes as [min_size],
       max_record_size_in_bytes as [max_size],
       avg_record_size_in_bytes as [avg_size]
from sys.dm_db_index_physical_stats(db_id(),object_id(N'Delivery.Orders'),1,null,'DETAILED');
go 

alter database SQLServerInternals 
set read_committed_snapshot off
with rollback immediate;
go