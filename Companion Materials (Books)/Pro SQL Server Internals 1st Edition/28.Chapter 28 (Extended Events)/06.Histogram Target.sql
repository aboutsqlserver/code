/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                       Chapter 28. Extended Events                        */
/*                            Histogram Target                              */
/****************************************************************************/

set noexec off
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 10 
begin
	raiserror('You should have SQL Server 2008+ to execute this script',16,1) with nowait
	set noexec on
end
go

if exists
(
	select * 
	from sys.server_event_sessions
	where name = 'DBUsage'
)
	drop event session DBUsage on server
go

/*** Examining lock_acquired event data columns ***/
select column_id, name, type_name
from sys.dm_xe_object_columns
where column_type = 'data' and object_name = 'lock_acquired'
go

/*** Examining lock_resource_type and lock_owner_type maps ***/
select name, map_key, map_value
from sys.dm_xe_map_values
where name = 'lock_resource_type'
order by map_key;

select name, map_key, map_value
from sys.dm_xe_map_values
where name = 'lock_owner_type'
order by map_key;
go



if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) = 10 -- SQL Server 2008
begin -- SQL Server 2008	
	exec sp_executesql N'
create event session DBUsage
on server
add event
	sqlserver.lock_acquired
	(
		where
			database_id > 4 and -- Users DB
			owner_type = 4 and	-- SharedXactWorkspace
			resource_type = 2 and -- DB-level lock
			sqlserver.is_system = 0 
	)
add target 
	package0.asynchronous_bucketizer
	(
		set 
			slots = 32 -- Based on # of DB
			,filtering_event_name = ''sqlserver.lock_acquired''
			,source_type = 0 -- event data column
			,source = ''database_id'' -- grouping column
	)
with	
	(
		event_retention_mode=allow_single_event_loss
		,max_dispatch_latency=10 seconds
	);'
end
else begin -- SQL Server 2012+	
	exec sp_executesql N'
create event session DBUsage
on server
add event
	sqlserver.lock_acquired
	(
		where
			database_id > 4 and -- Users DB
			owner_type = 4 and	-- SharedXactWorkspace
			resource_type = 2 and -- DB-level lock
			sqlserver.is_system = 0 
	)
add target 
	package0.histogram
	(
		set 
			slots = 32 -- Based on # of DB
			,filtering_event_name = ''sqlserver.lock_acquired''
			,source_type = 0 -- event data column
			,source = ''database_id'' -- grouping column
	)
with	
	(
		event_retention_mode=allow_single_event_loss
		,max_dispatch_latency=10 seconds
	);'
end
go

alter event session DBUsage
on server
state=start;
go 

/*** Examining Session Data ***/
declare
	@TargetName sysname

select @TargetName = 
	case 
		when 
			convert(int,
				left(
					convert(nvarchar(128), serverproperty('ProductVersion')),
					charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
				)
			) = 10
		then 'asynchronous_bucketizer' -- Need to fix
		else 'histogram' 
	end

;with TargetData(Data)
as
(
	select convert(xml,st.target_data) as Data
	from sys.dm_xe_sessions s join sys.dm_xe_session_targets st on
		s.address = st.event_session_address
	where s.name = 'DBUsage' and st.target_name = @TargetName
)
,EventInfo([Count],[DBID])
as
(
	select
		t.e.value('@count','int') 
		,t.e.value('((./value)/text())[1]','smallint') 
	from 
		TargetData cross apply
			TargetData.Data.nodes('/HistogramTarget/Slot') as t(e)
)
select e.dbid, d.name, e.[Count]
from 
	sys.databases d left outer join EventInfo e on
		e.DBID = d.database_id
where
	d.database_id > 4
order by 
	e.Count





