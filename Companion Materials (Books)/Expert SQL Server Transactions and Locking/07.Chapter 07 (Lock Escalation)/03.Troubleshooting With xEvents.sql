/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 07. Lock Escalation				            */
/*            Troubleshooting Lock Escalation with xEvents                  */
/****************************************************************************/

set noexec off
go

use SQLServerInternals
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 11 
begin
	raiserror('You should have SQL Server 2012+ to execute this script',16,1) with nowait;
	set noexec on
end
go

if exists(select * from sys.server_event_sessions where name = 'LockEscalationInfo') drop event session LockEscalationInfo on server;
go

/*** Examining lock_escalation event data columns ***/
select column_id, name, type_name
from sys.dm_xe_object_columns
where column_type = 'data' and object_name = 'lock_escalation';
go

create event session LockEscalationInfo
on server
add event
	sqlserver.lock_escalation
	(
		where
			database_id = 5  -- DB_ID()
	)
add target 
	package0.histogram
	(
		set 
			slots = 1024 -- Based on # of tables in the database
			,filtering_event_name = 'sqlserver.lock_escalation'
			,source_type = 0 -- event data column
			,source = 'object_id' -- grouping column
	)
with	
	(
		event_retention_mode=allow_single_event_loss
		,max_dispatch_latency=10 seconds
	);

alter event session LockEscalationInfo
on server
state=start;
go 

/*** Examining Session Data ***/
;with TargetData(Data)
as
(
	select convert(xml,st.target_data) as Data
	from sys.dm_xe_sessions s join sys.dm_xe_session_targets st on
		s.address = st.event_session_address
	where s.name = 'LockEscalationInfo' and st.target_name = 'histogram'
)
,EventInfo([count],object_id)
as
(
	select
		t.e.value('@count','int') 
		,t.e.value('((./value)/text())[1]','int') 
	from 
		TargetData cross apply
			TargetData.Data.nodes('/HistogramTarget/Slot') as t(e)
)
select 
	e.object_id
	, s.name + '.' + t.name as [table]
	, e.[count]
from 
	EventInfo e join sys.tables t on
		e.object_id = t.object_id
	join sys.schemas s on
		t.schema_id = s.schema_id
order by 
	e.count desc;

-- Clean-up
alter event session LockEscalationInfo
on server
state=stop;
go 

drop event session LockEscalationInfo on server;
go





