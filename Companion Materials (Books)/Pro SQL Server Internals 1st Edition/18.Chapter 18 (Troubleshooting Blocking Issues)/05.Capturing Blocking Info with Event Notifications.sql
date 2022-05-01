/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                Chapter 18. Troubleshooting Blocking Issues               */
/*             Capturing Blocking Info with Event Notifications             */
/****************************************************************************/
set noexec off
go

use master
go

/****************************************************************************/
/* The script creates EventMonitoring database and stores blocking info     */
/*         there. You can use different database if needed.                 */
/*                                                                          */
/* Script requires SQL Server 2008+ to run due to MERGE operator. You can   */
/*   hange the script using UPDATE/INSERT to make it compatible with SQL    */
/*                             Server 2005                                  */
/****************************************************************************/

if convert(int,
		left(
			convert(nvarchar(128), serverproperty('ProductVersion')),
			charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
		)
	) < 10
begin
	raiserror('Script requires SQL Server 2008+ to run',16,1) with nowait
	raiserror('You can change MERGE operator to INSERT/UPDATE operators to make it compatible with SQL Server 2005',0,1) with nowait
	set noexec on
end
go

-- drop event notification BlockedProcessNotificationEvent on server
if exists
(
	select * 
	from sys.server_event_notifications
	where name = 'BlockedProcessNotificationEvent'
)
begin
	raiserror('BlockedProcessNotificationEvent event notification session already exists',16,1) with nowait
	set noexec on
end
go	

if exists
(
	select * 
	from sys.configurations 
	where name = N'blocked process threshold (s)' and value = 0
)
begin
	raiserror('Blocked Process Threshold is not set',16,1) with nowait
	raiserror('You can enable it with the following statement',0,1) with nowait
	raiserror(N'
sp_configure ''show advanced options'', 1;
go
reconfigure;
go
sp_configure ''blocked process threshold'', 20; -- time in seconds
go
reconfigure;
go',0,1) with nowait
	set noexec on
end
go	

if not exists
(
	select * 
	from sys.databases
	where name = 'EventMonitoring'
)
begin
	raiserror('Creating Database EventMonitoring',0,1) with nowait
	create database EventMonitoring;
	exec sp_executesql 
		N'alter database EventMonitoring set enable_broker;
		alter database EventMonitoring set recovery simple;'
end
go

use EventMonitoring
go

if exists
(
	select *
	from sys.services
	where name = 'BlockedProcessNotificationService'
)
	drop service BlockedProcessNotificationService
go

if exists
(
	select *
	from sys.service_queues q join sys.schemas s on
		q.schema_id = s.schema_id
	where 
		s.name = 'dbo' and q.name = 'BlockedProcessNotificationQueue'
)
	drop queue dbo.BlockedProcessNotificationQueue
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'BlockedProcessesInfo'    
)
	drop table dbo.BlockedProcessesInfo
go

if exists(
	select * 
	from sys.procedures p join sys.schemas s on 
		p.schema_id = s.schema_id
	where 
		p.name = 'SB_BlockedProcessReport_Activation' and s.name = 'dbo' 
)
	drop proc dbo.SB_BlockedProcessReport_Activation
go

create queue dbo.BlockedProcessNotificationQueue
with status = on
go

create service BlockedProcessNotificationService
on queue dbo.BlockedProcessNotificationQueue
([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
go

create event notification BlockedProcessNotificationEvent 
on server 
for BLOCKED_PROCESS_REPORT
to service 
	'BlockedProcessNotificationService', 
	'current database' 
GO

create table dbo.BlockedProcessesInfo
(
	ID int not null identity(1,1),
	EventDate datetime not null,
	-- ID of the database where locking occurs
	DatabaseID smallint not null,
	-- Blocking resource
	[Resource] varchar(64) not null,
	-- Wait time in MS
	WaitTime int not null,
	-- Raw blocked process report
	BlockedProcessReport xml not null,
	-- SPID of the blocked process
	BlockedSPID smallint not null,
	-- XACTID of the blocked process
	BlockedXactId bigint null,
	-- Blocked Lock Request Mode
	BlockedLockMode varchar(16) null,
	-- Transaction isolation level for
	-- blocked session
	BlockedIsolationLevel varchar(32) null,
	-- Top SQL Handle from execution stack
	BlockedSQLHandle varbinary(64) null,
	-- Blocked SQL Statement Start offset
	BlockedStmtStart int null,
	-- Blocked SQL Statement End offset
	BlockedStmtEnd int null,
	-- Blocked SQL based on SQL Handle
	BlockedSql nvarchar(max) null,
	-- Blocked InputBuf from the report
	BlockedInputBuf nvarchar(max), 
	-- Blocked Plan based on SQL Handle
	BlockedQueryPlan xml null,
	-- SPID of the blocking process
	BlockingSPID smallint null,
	-- Blocking Process status
	BlockingStatus varchar(16) null,
	-- Blocking Process Transaction Count
	BlockingTranCount int null, 
	-- Blocking InputBuf from the report
	BlockingInputBuf nvarchar(max) null,
	-- Blocked SQL based on SQL Handle
	BlockingSql nvarchar(max) null,
	-- Blocking Plan based on SQL Handle
	BlockingQueryPlan xml null,
	constraint PK_BlockedProcessesInfo
	primary key nonclustered(ID)
)
go

create unique clustered index IDX_BlockedProcessInfo_EventDate_ID
on dbo.BlockedProcessesInfo(EventDate, ID)
go

create procedure [dbo].[SB_BlockedProcessReport_Activation]
with execute as owner
as
begin
	set nocount on
    
	declare
		@Msg varbinary(max)
		,@Ch uniqueidentifier
		,@MsgType sysname      
		,@Report xml
		,@EventDate datetime
		,@DBID smallint
		,@EventType varchar(128)
       
	while 1 = 1
	begin
		begin try
			begin tran
				-- for simplicity sake of that example
				-- we are processing data in one-by-one facion      
				-- rather than load everything to the temporary
				-- table variable
				waitfor 
				(
					receive top (1)
						@ch = conversation_handle
						,@Msg = message_body
						,@MsgType = message_type_name
					from dbo.BlockedProcessNotificationQueue
				), timeout 10000

				if @@ROWCOUNT = 0
				begin
					rollback
					break
				end          

				if @MsgType = N'http://schemas.microsoft.com/SQL/Notifications/EventNotification'
				begin
					select 
						@EventDate = convert(xml,@Msg).value('/EVENT_INSTANCE[1]/StartTime[1]','datetime')
						,@DBID = convert(xml,@Msg).value('/EVENT_INSTANCE[1]/DatabaseID[1]','smallint')
						,@EventType = convert(xml,@Msg).value('/EVENT_INSTANCE[1]/EventType[1]','varchar(128)')
						
					if @EventType = 'BLOCKED_PROCESS_REPORT'
					begin
						select                  
							@Report = convert(xml,@Msg).query('/EVENT_INSTANCE[1]/TextData[1]/*')

						merge into dbo.BlockedProcessesInfo as Source
						using
						(
							select 
								repData.[Resource], repData.WaitTime
								,repData.BlockedSPID, repData.BlockedLockMode, repData.BlockedIsolationLevel
								,repData.BlockedSqlHandle, repData.BlockedStmtStart, repData.BlockedStmtEnd
								,repData.BlockedInputBuf, repData.BlockingSPID, repData.BlockingStatus
								,repData.BlockingTranCount, repData.BlockedXactID
								,SUBSTRING(
									BlockedSQLText.Text, 
									(repData.BlockedStmtStart / 2) + 1,
									((
										CASE repData.BlockedStmtEnd
											WHEN -1 
											THEN DATALENGTH(BlockedSQLText.text)
											ELSE repData.BlockedStmtEnd
										END - repData.BlockedStmtStart) / 2) + 1
								) as BlockedSQL
								,coalesce(blockedERPlan.query_plan,blockedQSPlan.query_plan) as BlockedQueryPlan
								,SUBSTRING(
									BlockingSQLText.Text, 
									(repData.BlockingStmtStart / 2) + 1,
									((
										CASE repData.BlockingStmtEnd
											WHEN -1 
											THEN DATALENGTH(BlockingSQLText.text)
											ELSE repData.BlockingStmtEnd
										END - repData.BlockingStmtStart) / 2) + 1
								) as BlockingSQL
								,repData.BlockingInputBuf
								,BlockingQSPlan.query_plan as BlockingQueryPlan	               
							from
								-- Parsing report XML
								(
									select 
										@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@waitresource','varchar(64)') as [Resource]
										,@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@xactid','bigint') as BlockedXactID
										,@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@waittime','int') as WaitTime
										,@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@spid','smallint') as BlockedSPID
										,@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@lockMode','varchar(16)') as BlockedLockMode
										,@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@isolationlevel','varchar(32)') as BlockedIsolationLevel
										,@Report.value('xs:hexBinary(substring((/blocked-process-report[1]/blocked-process[1]/process[1]/executionStack[1]/frame[1]/@sqlhandle)[1],3))','varbinary(max)') as BlockedSQLHandle
										,isnull(@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/executionStack[1]/frame[1]/@stmtstart','int'), 0) as BlockedStmtStart
										,isnull(@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/executionStack[1]/frame[1]/@stmtend','int'), -1) as BlockedStmtEnd
										,@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/inputbuf[1]','nvarchar(max)') as BlockedInputBuf
										,@Report.value('/blocked-process-report[1]/blocking-process[1]/process[1]/@spid','smallint') as BlockingSPID
										,@Report.value('/blocked-process-report[1]/blocking-process[1]/process[1]/@status','varchar(16)') as BlockingStatus
										,@Report.value('/blocked-process-report[1]/blocking-process[1]/process[1]/@trancount','smallint') as BlockingTranCount
										,@Report.value('/blocked-process-report[1]/blocking-process[1]/process[1]/inputbuf[1]','nvarchar(max)') as BlockingInputBuf
										,@Report.value('xs:hexBinary(substring((/blocked-process-report[1]/blocking-process[1]/process[1]/executionStack[1]/frame[1]/@sqlhandle)[1],3))','varbinary(max)') as BlockingSQLHandle
										,isnull(@Report.value('/blocked-process-report[1]/blocking-process[1]/process[1]/executionStack[1]/frame[1]/@stmtstart','int'), 0) as BlockingStmtStart
										,isnull(@Report.value('/blocked-process-report[1]/blocking-process[1]/process[1]/executionStack[1]/frame[1]/@stmtend','int'), -1) as BlockingStmtEnd										
										
								) as repData 
								-- Getting Query Text					
								outer apply 
								(
									select
										case 
											when IsNull(repData.BlockedSQLHandle,0x) = 0x
											then null
											else 
												(
													select text 
													from sys.dm_exec_sql_text(repData.BlockedSQLHandle)
												)
										end as Text
								) BlockedSQLText
								outer apply 
								(
									select
										case 
											when IsNull(repData.BlockingSQLHandle,0x) = 0x
											then null
											else 
												(
													select text 
													from sys.dm_exec_sql_text(repData.BlockingSQLHandle)
												)
										end as Text
								) BlockingSQLText
								-- Check if statement is still blocked in sys.dm_exec_requests
								outer apply
								(
									select  qp.query_plan
									from 
										sys.dm_exec_requests er
											cross apply sys.dm_exec_query_plan(er.plan_handle) qp
									where 
										er.session_id = repData.BlockedSPID and 
										er.sql_handle = repData.BlockedSQLHandle and 
										er.statement_start_offset = repData.BlockedStmtStart and
										er.statement_end_offset = repData.BlockedStmtEnd
								) blockedERPlan
								-- if there is no plan handle let's try sys.dm_exec_query_stats
								outer apply
								(
									select
										case 
											when blockedERPlan.query_plan is null
											then
												(
													select top 1 qp.query_plan
													from
														sys.dm_exec_query_stats qs with (nolock) 
															cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
													where	
														qs.sql_handle = repData.BlockedSQLHandle and 
														qs.statement_start_offset = repData.BlockedStmtStart and
														qs.statement_end_offset = repData.BlockedStmtEnd and
														@EventDate between qs.creation_time and qs.last_execution_time                         
													order by
														qs.last_execution_time desc
												) 
										end as query_plan
								) blockedQSPlan  		
								outer apply
								(
									select top 1 qp.query_plan
									from
										sys.dm_exec_query_stats qs with (nolock) 
											cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
									where	
										qs.sql_handle = repData.BlockingSQLHandle and 
										qs.statement_start_offset = repData.BlockingStmtStart and
										qs.statement_end_offset = repData.BlockingStmtEnd 
									order by
										qs.last_execution_time desc
								) BlockingQSPlan  			               
						) as Target			
						on 
							Source.BlockedSPID = target.BlockedSPID and
							IsNull(Source.BlockedXactId,-1) = IsNull(target.BlockedXactId,-1) and              
							Source.[Resource] = target.[Resource] and              
							Source.BlockingSPID = target.BlockingSPID and
							Source.BlockedSQLHandle = target.BlockedSQLHandle and              
							Source.BlockedStmtStart = target.BlockedStmtStart and   
							Source.BlockedStmtEnd = target.BlockedStmtEnd and   
							Source.EventDate >= dateadd(millisecond,-target.WaitTime - 100, @EventDate)
						when matched then
							update set source.WaitTime = target.WaitTime
						when not matched then
							insert (EventDate,DatabaseID,[Resource],WaitTime,BlockedProcessReport,BlockedSPID
								,BlockedXactId,BlockedLockMode,BlockedIsolationLevel,BlockedSQLHandle,BlockedStmtStart
								,BlockedStmtEnd,BlockedSql,BlockedInputBuf,BlockedQueryPlan,BlockingSPID,BlockingStatus
								,BlockingTranCount,BlockingSql,BlockingInputBuf,BlockingQueryPlan)          
							values(@EventDate,@DBID,Target.[Resource],Target.WaitTime
								,@Report,Target.BlockedSPID,Target.BlockedXactId,Target.BlockedLockMode
								,Target.BlockedIsolationLevel,Target.BlockedSQLHandle,Target.BlockedStmtStart
								,Target.BlockedStmtEnd,Target.BlockedSql,Target.BlockedInputBuf,Target.BlockedQueryPlan
								,Target.BlockingSPID,Target.BlockingStatus,Target.BlockingTranCount
								,Target.BlockingSql,Target.BlockingInputBuf,Target.BlockingQueryPlan);

						-- Perhaps send email here?
					end -- @EventType = BLOCKED_PROCESS_REPORT
				end -- @MsgType = http://schemas.microsoft.com/SQL/Notifications/EventNotification
				else if @MsgType = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
					end conversation @ch
				-- else handle errors here
			commit
		end try
		begin catch
			-- capture info about error message here      
			if @@TRANCOUNT > 0
				rollback;      

			-- perhaps add some Email Notification here
			-- Do not forget about the fact that SP is running from Service Broker
			-- you need to either setup certificate based security or set TRUSTWORTHY ON
			-- in order to use DB Mail
			break
		end catch
	end
end
go    

-- At this point you need to set up security to allow stored procedure to access DMV and/or use db mail
-- You have 2 options
-- 1st (not recommended) is marking database as Trustworty with ALTER DATABASE EventMonitoring SET TRUSTWORTHY ON command
-- 2nd is setting up certificate-based secutiry
-- Listing below shows second approach

alter queue dbo.BlockedProcessNotificationQueue
with 
	status = ON,
	retention = OFF,
	activation
	(
		Status = off,
		Procedure_Name = dbo.SB_BlockedProcessReport_Activation,
		max_queue_readers = 1, 
		execute as owner
	)
go

use EventMonitoring
go

if exists
(
	select * 
	from sys.crypt_properties 
	where major_id = object_id(N'dbo.SB_BlockedProcessReport_Activation') and 
		crypt_type = 'SPVC'
)
	drop signature from dbo.SB_BlockedProcessReport_Activation
	by certificate EventMonitoringCert
go

if exists
(
	select * 
	from sys.database_principals
	where name = 'EventMonitoringUser' and type = 'S'
)
	drop user EventMonitoringUser
go

if exists
(
	select * 
	from sys.certificates
	where name = 'EventMonitoringCert' 
)
	drop certificate EventMonitoringCert
go

use master
go

if exists
(
	select * 
	from sys.server_principals
	where name = 'EventMonitoringLogin' and type = 'C'
)
	drop login EventMonitoringLogin
go

if exists
(
	select * 
	from sys.certificates
	where name = 'EventMonitoringCert' 
)
	drop certificate EventMonitoringCert
go

-- Security setup
use EventMonitoring
go

if not exists 
(
	select * 
	from sys.symmetric_keys 
	where symmetric_key_id = 101
)
	create master key encryption 
	by password = 'Pas$word1'
go

create certificate EventMonitoringCert 
with subject = 'Cert for event monitoring', 
expiry_date = '20201031';
go

-- We need to re-sign every time we alter 
-- the stored procedure
add signature to dbo.SB_BlockedProcessReport_Activation
by certificate EventMonitoringCert
go

backup certificate EventMonitoringCert
to file='EventMonitoringCert.cer'
go

use master
go

create certificate EventMonitoringCert
from file='EventMonitoringCert.cer'
go

create login EventMonitoringLogin
from certificate EventMonitoringCert
go

grant view server state, 
	authenticate server to EventMonitoringLogin
go

/*** Enable SB queue ***/
use EventMonitoring
go

select * 
from dbo.BlockedProcessNotificationQueue
go

-- You can enable activation now or after testing as shown below
alter queue dbo.BlockedProcessNotificationQueue
with 
	status = ON,
	retention = OFF,
	activation
	(
		Status = ON,
		Procedure_Name = dbo.SB_BlockedProcessReport_Activation,
		max_queue_readers = 1, 
		execute as owner
	)
go

/*** Testing ***/
use tempdb
go

create table dbo.Data
(
	ID int not null,
	Value int not null,

	constraint PK_Data
	primary key clustered(ID)
)
go

insert into dbo.Data
values(1,1),(2,2),(3,3),(4,4)
go

-- Session 1 code
begin tran
	update dbo.Data 
	set  Value = Value + 1
	where ID = 2

	-- run session 2 code below and wait for some time
commit
go

-- Session 2 code
select count(*)
from dbo.data
go

-- checking queue. Make sure first session has been committed
use EventMonitoring
go

select * 
from dbo.BlockedProcessNotificationQueue
go

alter queue dbo.BlockedProcessNotificationQueue
with 
	status = ON,
	retention = OFF,
	activation
	(
		Status = ON,
		Procedure_Name = dbo.SB_BlockedProcessReport_Activation,
		MAX_QUEUE_READERS = 1, 
		EXECUTE AS OWNER
	)
go

select * from dbo.BlockedProcessesInfo
go