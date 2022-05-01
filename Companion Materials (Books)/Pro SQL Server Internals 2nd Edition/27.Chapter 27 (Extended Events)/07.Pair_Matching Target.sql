/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 27. Extended Events                        */
/*                          Pair_Matching Target                            */
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
	raiserror('You should have SQL Server 2008+ to execute this script',16,1) with nowait;
	set noexec on
end
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 11 -- SQL Server 2012/2014 is required
begin
	raiserror('SQL Server 2008/2008R2 does not support "statement" in the matching columns.',16,1) with nowait;
	raiserror('However, you can work with pair_matching target the same way as it is shown here',16,1) with nowait;
	set noexec on
end
go

if exists(select * from sys.server_event_sessions where name = 'Timeouts') drop event session Timeouts on server;
go

create event session [Timeouts]
on server
add event 
	sqlserver.sql_statement_starting
	(    
		action (sqlserver.session_id)
	),
add event 
	sqlserver.sql_statement_completed
	(    
		action (sqlserver.session_id)
	)
add target
	package0.pair_matching
	(
		set
			begin_event = 'sqlserver.sql_statement_starting'
			,begin_matching_columns = 'statement'
			,begin_matching_actions = 'sqlserver.session_id'
			,end_event = 'sqlserver.sql_statement_completed'
			,end_matching_columns = 'statement'
			,end_matching_actions = 'sqlserver.session_id'
			,respond_to_memory_pressure = 0
	)
with	
	(
		max_dispatch_latency=10 seconds
		,track_causality=on
	);

alter event session Timeouts
on server
state=start;
go 

;with TargetData(Data)
as
(
	select convert(xml,st.target_data) as Data
	from sys.dm_xe_sessions s join sys.dm_xe_session_targets st on
		s.address = st.event_session_address
	where s.name = 'Timeouts' and st.target_name = 'pair_matching'
)
select
	t.e.value('@timestamp','datetime') as [Event Time]
	,t.e.value('@name','sysname') as [Event]
	,t.e.value('(action[@name="session_id"]/value/text())[1]','smallint') 
		as [SPID]
	,t.e.value('(data[@name="statement"]/value/text())[1]','nvarchar(max)')
		as [SQL]
from 
	TargetData cross apply
		TargetData.Data.nodes('/PairingTarget/event') as t(e);
go

-- Clean-Up
alter event session Timeouts
on server
state=stop;
go 

drop event session Timeouts on server;
