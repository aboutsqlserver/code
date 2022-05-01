/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 12. Troubleshooting Concurrency Issues              */
/*                 Index Usage and Operational Stats Analysis               */
/****************************************************************************/

-- Run in context of the database you analyze
select top 10
	t.object_id
	,i.index_id
	,sch.name + '.' + t.name as [table]
	,i.name as [index]
	,ius.user_seeks
	,ius.user_scans 
	,ius.user_lookups
	,ius.user_seeks + ius.user_scans + ius.user_lookups as reads
	,ius.user_updates
	,ius.last_user_seek
	,ius.last_user_scan
	,ius.last_user_lookup 
	,ius.last_user_update 
	,ios.*
from 
	sys.tables t with (nolock) join sys.indexes i with (nolock) on
		t.object_id = i.object_id
	join sys.schemas sch with (nolock)  on
		t.schema_id = sch.schema_id
	left join sys.dm_db_index_usage_stats ius with (nolock) on 
		i.object_id = ius.object_id and 
		i.index_id = ius.index_id
	outer apply
	(
		select 
			sum(range_scan_count) as range_scan_count
			,sum(singleton_lookup_count) as singleton_lookup_count
			,sum(row_lock_wait_count) as row_lock_wait_count
			,sum(row_lock_wait_in_ms) as row_lock_wait_in_ms
			,sum(page_lock_wait_count) as page_lock_wait_count
			,sum(page_lock_wait_in_ms) as page_lock_wait_in_ms
			,sum(page_latch_wait_count) as page_latch_wait_count
			,sum(page_latch_wait_in_ms) as page_latch_wait_in_ms
			,sum(page_io_latch_wait_count) as page_io_latch_wait_count
			,sum(page_io_latch_wait_in_ms) as page_io_latch_wait_in_ms
		from sys.dm_db_index_operational_stats(db_id(),i.object_id,i.index_id,null)
	) ios
order by
	ios.row_lock_wait_in_ms + ios.page_lock_wait_in_ms desc
option (maxdop 1)
go