/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 27. Extended Events                        */
/*                            Ring_Buffer Target                            */
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
	raiserror('However, you can work with ring_buffer target the same way as it is shown here',16,1) with nowait;
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

/****************************************************************************/
/* Keep in mind that target_data XML column in sys.dm_xe_session_targets    */
/* view is limited to 4MB output and it could skip some events from the     */
/* ring_buffer target. It is safer to use file-based target to avoid that.  */    
/****************************************************************************/

;with TargetData(Data)
as
(
	select convert(xml,st.target_data) as Data
	from sys.dm_xe_sessions s join sys.dm_xe_session_targets st on
		s.address = st.event_session_address
	where s.name = 'TempDB Spills' and st.target_name = 'ring_buffer'
)
,EventInfo([Event Time],[Event],SPID,[SQL],PlanHandle)
as
(
	select
		t.e.value('@timestamp','datetime') as [Event Time]
		,t.e.value('@name','sysname') as [Event]
		,t.e.value('(action[@name="session_id"]/value)[1]','smallint') 
				as [SPID]
		,t.e.value('(action[@name="sql_text"]/value)[1]','nvarchar(max)')
				as [SQL]
		,t.e.value('xs:hexBinary((action[@name="plan_handle"]/value)[1])'
				,'varbinary(64)') as [PlanHandle]
	from 
		TargetData cross apply
			TargetData.Data.nodes('/RingBufferTarget/event') as t(e)
)
select 
	ei.[Event Time], ei.[Event], ei.SPID, ei.SQL, qp.Query_Plan
from 
	EventInfo ei 
		outer apply sys.dm_exec_query_plan(ei.PlanHandle) qp;
go
