/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                       Chapter 28. Extended Events                        */
/*                          Event_Counter Target                            */
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
	where name = 'FileStats'
)
	drop event session FileStats on server
go


if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) = 10 -- SQL Server 2008
begin -- SQL Server 2008	
	exec sp_executesql N'
create event session [FileStats] 
on server
add event
	sqlserver.file_read_completed
	(
		where(sqlserver.database_id = 2)
	),
add event
	sqlserver.file_write_completed
	(
		where(sqlserver.database_id = 2)
	)
add target
	package0.synchronous_event_counter
with	
	(
		event_retention_mode=allow_single_event_loss
		,max_dispatch_latency=5 seconds
	);'
end
else begin -- SQL Server 2012+	
	exec sp_executesql N'
create event session [FileStats] 
on server
add event
	sqlserver.file_read_completed
	(
		where(sqlserver.database_id = 2)
	),
add event
	sqlserver.file_write_completed
	(
		where(sqlserver.database_id = 2)
	)
add target
	package0.event_counter
with	
	(
		event_retention_mode=allow_single_event_loss
		,max_dispatch_latency=5 seconds
	);'
end
go

alter event session [FileStats]
on server
state=start;
go 

raiserror('You can trigger tempdb activity with Chapter 3 "04.Statistics and Memory Grants.sql" script',0,1) with nowait
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
		then 'synchronous_event_counter'
		else 'event_counter' 
	end

;with TargetData(Data)
as
(
	select convert(xml,st.target_data) as Data
	from sys.dm_xe_sessions s join sys.dm_xe_session_targets st on
		s.address = st.event_session_address
	where s.name = 'FileStats' and st.target_name = @TargetName
)
,EventInfo([Event],[Count])
as
(
	select
		t.e.value('@name','sysname') as [Event]
		,t.e.value('@count','bigint') as [Count]
	from 
		TargetData cross apply
			TargetData.Data.nodes
	 	 ('/CounterTarget/Packages/Package[@name="sqlserver"]/Event') 
				as t(e)
)
select [Event], [Count]
from EventInfo;
go




