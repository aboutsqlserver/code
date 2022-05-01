/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 27. Extended Events                        */
/*                            Event_File Target                             */
/****************************************************************************/

set noexec off
go


if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 11 -- SQL Server 2012/2014 is required
begin
	raiserror('SQL Server 2008/2008R2 does not support hash_warning/sort_warning events',16,1) with nowait;
	raiserror('However, you can work with asynchronous_file_target target the same way as it is shown here',16,1) with nowait;
	set noexec on
end
go

if not exists
(
	select * 
	from sys.dm_xe_sessions
	where name = 'TempDB Spills'
)
begin
	raiserror('Session [TempDB Spills] is not active',16,1) with nowait;
	raiserror('Create and start session using "02.Monitoring TempDB Spills.sql" script',16,1) with nowait;
	set noexec on
end
go

raiserror('You can trigger tempdb spill with Chapter 3'' "04.Statistics and Memory Grants.sql" script',0,1) with nowait;
go

/*** Obtaining File Name from the target ***/

-- SQL Server 2012/2014: 
declare
	@dataFile nvarchar(260)

-- Get path to event data file 
select 
	@dataFile = 
		left(column_value,len(column_value ) -
			charindex('.',reverse(column_value))) + '*.' +
      		right(column_value, charindex('.',reverse(column_value))-1)
from 
	sys.dm_xe_session_object_columns oc join sys.dm_xe_sessions s on
		oc.event_session_address = s.address
where
	s.name = 'TempDB Spills' and
	oc.object_name = 'event_file' and 
	oc.column_name = 'filename';

select @dataFile as [Data File Path];
go

-- SQL Server 2008/2008R2: 
declare
	@dataFile nvarchar(512)
	,@metaFile nvarchar(512)

-- Get path to event data file 
select 
	@dataFile = 
		left(column_value,len(column_value ) -
			charindex('.',reverse(column_value))) +	'*.' +
		right(column_value, charindex('.',reverse(column_value))-1)
from 
	sys.dm_xe_session_object_columns oc join sys.dm_xe_sessions s on
		oc.event_session_address = s.address
where
	s.name = 'TempDB Spills' and
	oc.object_name = 'asynchronous_file_target' and 
	oc.column_name = 'filename';

-- Get path to metadata file
select 
	@metaFile = 
		left(column_value,len(column_value ) -
			charindex('.',reverse(column_value))) + '*.' +
		right(column_value, charindex('.',reverse(column_value))-1)
from 
	sys.dm_xe_session_object_columns oc join sys.dm_xe_sessions s on
		oc.event_session_address = s.address
where
	s.name = 'TempDB Spills' and
	oc.object_name = 'asynchronous_file_target' and 
	oc.column_name = 'metadatafile';

if @metaFile is null
	select @metaFile = 
		left(@dataFile,len(@dataFile) - 
			charindex('*',reverse(@dataFile))) + '*.xem';

select @dataFile as [Data File Path], @metaFile as [Metadata File Path];
go

/*** Reading Data from Event_File target ***/
;with TargetData(Data, File_Name, File_Offset)
as
(
	select CONVERT(xml,event_data) as Data, file_name, file_offset 
	from 
		sys.fn_xe_file_target_read_file
	 	 	 ('c:\extevents\TempDB_Spiils*.xel'  -- Data File
			 ,null -- Metadata File - not required in SQL Server 2012+
			 ,null
			 ,null)
)
,EventInfo([Event Time], [Event], SPID, [SQL], PlanHandle
	,File_Name, File_Offset)
as
(
	select
		Data.value('/event[1]/@timestamp','datetime') as [Event Time]
		,Data.value('/event[1]/@name','sysname') as [Event]
		,Data.value('(/event[1]/action[@name="session_id"]/value)[1]'
			,'smallint') 	as [SPID]
		,Data.value('(/event[1]/action[@name="sql_text"]/value)[1]'
			,'nvarchar(max)') as [SQL]
		,Data.value(
	'xs:hexBinary((/event[1]/action[@name="plan_handle"]/value)[1])'
			,'varbinary(64)') as [PlanHandle]
		,File_Name
		,File_Offset
	from 
		TargetData 
)
select 
	ei.[Event Time], ei.File_Name, ei.File_Offset
	,ei.[Event], ei.SPID, ei.SQL, qp.Query_Plan
from 
	EventInfo ei 
		outer apply sys.dm_exec_query_plan(ei.PlanHandle) qp;
go

