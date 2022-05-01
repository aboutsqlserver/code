/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                        Chapter 29. Query Store                           */
/*                         Configure Query Store                            */
/****************************************************************************/

set noexec off
go

if convert(int,
		left(
			convert(nvarchar(128), serverproperty('ProductVersion')),
			charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
		)
	) < 13
begin
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

use SQLServerInternals
go

-- Enabling Query Store
alter database SQLServerInternals set query_store = on;
go

-- Allowing Query Store to collect data
alter database SQLServerInternals set query_store (operation_mode = read_write);
go

-- Other configuration options
-- In many cases, default options will work
-- You should disable automatic clean-up mode in non-Enterprise Editions of RTM/CU1 build due to the bug in SQL Server
alter database SQLServerInternals set query_store 
(
	cleanup_policy = (stale_query_threshold_days = 30) -- How long queries are retained
	,data_flush_interval_seconds = 900 -- How often data is flushed to the disk 
	,interval_length_minutes = 1 -- Aggregation interval. Using 1 minute for demo purposes. Use larger intervals in production
	,max_storage_size_mb = 100 -- Max Size on disk
	,query_capture_mode = all -- All queries will be captures
	,size_based_cleanup_mode = off -- Disable auto-cleanup
);
go