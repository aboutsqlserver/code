/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                       Chapter 28. Extended Events                        */
/*                            Expensive Queries                             */
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
	where name = 'Expensive Queries'
)
begin
	drop event session [Expensive Queries]  on server
end
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) = 10 -- SQL Server 2008
begin -- SQL Server 2008	
	exec sp_executesql N'
create event session [Expensive Queries] 
on server
add event
	sqlserver.sql_statement_completed
	(
		action	(sqlserver.plan_handle)
		where
		(
			(
				cpu >= 5000000 or -- Time in microseconds
				reads >= 10000 or
				writes >= 10000
			) and
			sqlserver.is_system = 0 
		)
	),
add event
	sqlserver.rpc_completed
	(
		where
		(
			(
				cpu >= 5000000 or
				reads >= 10000 or
				writes >= 10000
			) and
			sqlserver.is_system = 0 
		)
	)
 
add target 
	package0.asynchronous_file_target
	(
		set 
			filename = ''c:\ExtEvents\Expensive Queries.xel''
			,metadatafile = ''c:\ExtEvents\Expensive Queries.xem''
	)
with	
	(
		event_retention_mode=allow_single_event_loss
		,max_dispatch_latency=30 seconds
	);'
end
else begin -- SQL Server 2012+	
	exec sp_executesql N'
create event session [Expensive Queries] 
on server
add event
	sqlserver.sql_statement_completed
	(
		action	(sqlserver.plan_handle)
		where
		(
			(
				cpu_time >= 5000000 or -- Time in microseconds
				logical_reads >= 10000 or
				writes >= 10000
			) and
			sqlserver.is_system = 0 
		)
	),
add event
	sqlserver.rpc_completed
	(
		where
		(
			(
				cpu_time >= 5000000 or
				logical_reads >= 10000 or
				writes >= 10000
			) and
			sqlserver.is_system = 0 
		)
	)
 
add target 
	package0.event_file
	(
		set filename = ''c:\ExtEvents\Expensive Queries.xel''
	)
with	
	(
		event_retention_mode=allow_single_event_loss
		,max_dispatch_latency=30 seconds
	);'
end
go

alter event session [Expensive Queries]
on server
state=start;
go 

/*** Examining Session Data ***/
;with TargetData(Data, File_Name, File_Offset)
as
(
	select convert(xml,event_data) as Data, file_name, file_offset 
	from 
		sys.fn_xe_file_target_read_file
		(
			'c:\extevents\Expensive*.xel'
			,'c:\extevents\Expensive*.xem' -- Not Required in SQL Server 2012+
			,null
			,null
		)
)
,EventInfo([Event], [Event Time], [CPU Time], [Duration], [Logical Reads]
	,[Physical Reads], [Writes], [Rows], [Statement], [PlanHandle]
	,File_Name, File_Offset)
as
(
	select
		Data.value('/event[1]/@name','sysname') as [Event]
		,Data.value('/event[1]/@timestamp','datetime') as [Event Time]
		,Data.value('((/event[1]/data[@name="cpu_time"]/value/text())[1])','bigint') as [CPU Time]
		,Data.value('((/event[1]/data[@name="duration"]/value/text())[1])','bigint') as [Duration]
		,Data.value('((/event[1]/data[@name="logical_reads"]/value/text())[1])','int') as [Logical Reads]
		,Data.value('((/event[1]/data[@name="physical_reads"]/value/text())[1])','int') as [Physical Reads]
		,Data.value('((/event[1]/data[@name="writes"]/value/text())[1])','int') as [Writes]
		,Data.value('((/event[1]/data[@name="row_count"]/value/text())[1])','int') as [Rows]
		,Data.value('((/event[1]/data[@name="statement"]/value/text())[1])','nvarchar(max)') as [Statement]
		,Data.value('xs:hexBinary(((/event[1]/action[@name="plan_handle"]/value/text())[1]))','varbinary(64)') as [PlanHandle]
		,File_Name
		,File_Offset
	from 
		TargetData 
)
select
	ei.[Event], ei.[Event Time]
	,ei.[CPU Time] / 1000 as [CPU Time (ms)]
	,ei.[Duration] / 1000 as [Duration (ms)]
	,ei.[Logical Reads], ei.[Physical Reads], ei.[Writes]
	,ei.[Rows], ei.[Statement], ei.[PlanHandle]
	,ei.File_Name, ei.File_Offset, qp.Query_Plan
from 
	EventInfo ei 
		outer apply sys.dm_exec_query_plan(ei.PlanHandle) qp
