/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                        Chapter 29. Query Store                           */
/*                        Query Store Maintenance                           */
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

-- Analyzing Query Store Parameters
-- Look at current_storage_size_mb and max_storage_size_mb
select actual_state_desc, desired_state_desc, current_storage_size_mb   
	,max_storage_size_mb, readonly_reason, interval_length_minutes   
	,stale_query_threshold_days, size_based_cleanup_mode_desc   
	,query_capture_mode_desc  
from sys.database_query_store_options;
go

-- Removing old queries that ran only once
declare
	@RecId int = -1
	,@QueryId int
declare
	@Queries table
	(  
		RecId int not null identity(1,1) primary key,
		QueryId int not null  
	)

insert into @Queries(QueryId)
	select p.query_id
	from sys.query_store_plan p join sys.query_store_runtime_stats rs on  
		p.plan_id = rs.plan_id  
	group by 
		p.query_id
	having 
		sum(rs.count_executions) < 2 and 
		max(rs.last_execution_time) < dateadd(day,-72,getdate());

while 1 = 1
begin
	select top 1 @RecId = RecId, @QueryID = QueryId
	from @Queries
	where RecId > @RecId
	order by RecID;

	if @@rowcount = 0
		break;
	exec sys.sp_query_store_remove_query @QueryID;  
end;
go
