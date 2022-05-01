/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                              Initial Setup                               */
/*                    Creating Activation Procedures                        */
/****************************************************************************/

use DBA
go

-- @CollectPlan variable in stored procedures controls if stored procedures collect
-- execution plans. This may introduce CPU overhead on CPU-bound systems with large
-- amount of blocking. Disable it unless you need this feature

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'SB_BlockedProcessReport_Activation') drop proc dbo.SB_BlockedProcessReport_Activation;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'SB_DeadlockEvent_Activation') drop proc dbo.SB_DeadlockEvent_Activation;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'BMFrameworkErrorNotification') drop proc dbo.BMFrameworkErrorNotification;
if (object_id(N'dbo.fnGetSqlText','IF') is not null) drop function dbo.fnGetSqlText;
if (object_id(N'dbo.fnGetQueryInfoFromExecRequests','IF') is not null) drop function dbo.fnGetQueryInfoFromExecRequests;
if (object_id(N'dbo.fnGetQueryInfoFromQueryStats','IF') is not null) drop function dbo.fnGetQueryInfoFromQueryStats;
go

create function dbo.fnGetSqlText(@SqlHandle varbinary(64), @StmtStart int, @StmtEnd int)
returns table
/****************************************************************************/
/* Function: dbo.fnGetSqlText                                               */
/* Author: Dmitri V. Korotkevitch                                           */
/*                                                                          */
/* Purpose:                                                                 */ 
/*    Returns sql text based on sql_handle and statement start/end offsets  */
/*    Includes several safeguards to avoid exceptions                       */
/*                                                                          */
/* Return Values                                                            */ 
/*    1-column table with SQL text                                          */
/*                                                                          */
/* Version History:                                                         */ 
/*     v1.0 2018-08-01. Initial implementation                              */
/****************************************************************************/
as
return
(
	select
		substring(
			t.text
			,@StmtStart / 2 + 1
			,((
				case 
					when @StmtEnd = -1								
					then datalength(t.text)
					else @StmtEnd
				end - @StmtStart) / 2) + 1
		) as [SQL]
	from sys.dm_exec_sql_text(nullif(@SqlHandle,0x)) t
	where 
		isnulL(@SqlHandle,0x) <> 0x and
		-- In some rare cases, SQL Server may return empty sql text
		isnull(t.text,'') <> '' and 
		(case when @StmtEnd = -1 then datalength(t.text) else @StmtEnd end > @StmtStart)
)
go



create function dbo.fnGetQueryInfoFromExecRequests
(
	@collectPlan bit
	,@SPID smallint
	,@SqlHandle varbinary(64)
	,@StmtStart int
	,@StmtEnd int
)
/****************************************************************************/
/* Function: dbo.fnGetQueryInfoFromExecRequests                             */
/* Author: Dmitri V. Korotkevitch                                           */
/*                                                                          */
/* Purpose:                                                                 */ 
/*    Returns query and plan hashes, and optional query plan when           */  
/*    @collectPlan = 1 from sys.dm_exec_requests based on @@spid,           */
/*    sql_handle and statement start/end offsets                            */
/*                                                                          */
/* Return Values                                                            */ 
/*    1-row table	                                                        */
/*       DataExists = 1 when session is found in sys.dm_exec_requests       */
/*       query_hash, plan_hash, query_plan                                  */
/*                                                                          */
/*                                                                          */
/* Version History:                                                         */ 
/*     v1.0 2018-08-01. Initial implementation                              */
/****************************************************************************/
returns table
as
return
(
	select 
		1 as DataExists
		,er.query_plan_hash as plan_hash
		,er.query_hash 
		,case
			when @collectPlan = 1
			then
			(
				select qp.query_plan
				from sys.dm_exec_query_plan(er.plan_handle) qp
			)
			else null
		end as query_plan
		from 
			sys.dm_exec_requests er
		where 
			er.session_id = @SPID and 
			er.sql_handle = @SqlHandle and 
			er.statement_start_offset = @StmtStart and
			er.statement_end_offset = @StmtEnd
)
go

create function dbo.fnGetQueryInfoFromQueryStats
(
	@collectPlan bit
	,@SqlHandle varbinary(64)
	,@StmtStart int
	,@StmtEnd int
	,@EventDate datetime
	,@LastExecTimeBuffer int
)
/****************************************************************************/
/* Function: dbo.fnGetQueryInfoFromQueryStats                               */
/* Author: Dmitri V. Korotkevitch                                           */
/*                                                                          */
/* Purpose:                                                                 */ 
/*    Returns query and plan hashes, and optional query plan when           */  
/*    @collectPlan = 1 from sys.dm_exec_query_stats based on @@spid,        */
/*    sql_handle and statement start/end offsets. Checks that @EventDate is */
/*    in between created_date and last_executed_time values.                */
/*    @LastExecTimeBuffer allows to add seconds to last_executed_time       */
/*                                                                          */
/* Return Values                                                            */ 
/*    1-row table	                                                        */
/*       query_hash, plan_hash, query_plan                                  */
/*                                                                          */
/*                                                                          */
/* Version History:                                                         */ 
/*     v1.0 2018-08-01. Initial implementation                              */
/****************************************************************************/
returns table
as
return
(
	select top 1 
		qs.query_plan_hash as plan_hash
		,qs.query_hash
		,case 
			when @collectPlan = 1
			then
			(
				select qp.query_plan
				from sys.dm_exec_query_plan(qs.plan_handle) qp
			)
			else null
		end as query_plan
	from
		sys.dm_exec_query_stats qs with (nolock) 
	where	
		qs.sql_handle = @SqlHandle AND 
		qs.statement_start_offset = @StmtStart AND
		qs.statement_end_offset = @StmtEnd AND
		@EventDate BETWEEN qs.creation_time AND dateadd(second,@LastExecTimeBuffer,qs.last_execution_time)
	order by
		qs.last_execution_time desc 
)
go

create procedure dbo.BMFrameworkErrorNotification
(
	@Module sysname -- The name of the module where error occured
	,@IsPoisonMsg bit -- Indicates if message is potentially poison
	,@ErrorMsg nvarchar(512)
	,@ErrorLine int
	,@Report nvarchar(max) = null
)
with execute as owner
/****************************************************************************/
/* Proc: dbo.SBMFrameworkErrorNotification                                 */
/* Author: Dmitri V. Korotkevitch                                           */
/*                                                                          */
/* Purpose:                                                                 */ 
/*    Send error notification in case if blocked process report or deadlock */
/*    graph cannot be processed                                             */
/*                                                                          */
/* This SP can be customized for particular installations. It will not be   */
/* changed in upgrade scripts in the future versionbs                       */
/*                                                                          */
/* Version History:                                                         */ 
/*     v1.0 2018-08-01. Initial implementation                              */
/****************************************************************************/
as
begin
	/*
	declare
		@Recipient VARCHAR(255) = '<Recipients>',
		@Subject NVARCHAR(255) = @@SERVERNAME + ': ' + @Module + ' - Error',
		@Body NVARCHAR(MAX) = 'LINE: ' + convert(nvarchar(16), @ErrorLine) + char(13) + char(10) + 
			'ERROR:' + @ErrorMsg + char(13) + char(10) + 'Report:' + char(13) + char(10) +
			isnull(@Report,'<NULL>');
	
	if @IsPoisonMsg = 1
		@Subject = '(POISON MESSAGE): ' + @Subject;

	exec msdb.dbo.sp_send_dbmail
		@recipients = @Recipient, 
		@subject = @Subject, 
		@body = @Body;	
	*/
	return;
end
go

create procedure [dbo].[SB_BlockedProcessReport_Activation]
with execute as owner
/****************************************************************************/
/* Proc: dbo.SB_DeadlockEvent_Activation                                    */
/* Author: Dmitri V. Korotkevitch                                           */
/*                                                                          */
/* Purpose:                                                                 */ 
/*    Activation stored procedure for Blocked Processes Event Notification  */
/*                                                                          */
/* Version History:                                                         */ 
/*     v1.0 2018-08-01. Initial implementation                              */
/****************************************************************************/
as
begin
	set nocount on
    
	declare
		@Msg varbinary(max)
		,@serviceID int
		,@ch uniqueidentifier
		,@MsgType sysname      
		,@Report xml
		,@EventDate datetime
		,@DBID smallint
		,@EventType varchar(128)
		,@blockedSPID int
		,@blockedXactID bigint
		,@resource varchar(64)
		,@blockingSPID int
		,@blockedSqlHandle varbinary(64)
		,@blockedStmtStart int
		,@blockedStmtEnd int
		,@waitTime int
		,@blockedXML xml
		,@blockingXML xml
		,@collectPlan bit = 1 -- Controls if we collect execution plans
	
	declare
		@Module sysname = object_name(@@PROCID)
		,@IsPoisonMsg bit
		,@ErrorMsg nvarchar(256) 
		,@ErrorLine int
		,@ReportMsg nvarchar(max)

    if exists
	(
		select * 
		from dbo.BMFrameworkConfig
		where [Key] = 'CollectPlanFromBlockingReport' and [Value] = '0'
	)
		set @collectPlan = 0;
				  
	while 1 = 1
	begin
		begin try
			begin tran 
				waitfor 
				(
					receive top (1)
						@serviceID = service_id
						,@ch = conversation_handle
						,@Msg = message_body
						,@MsgType = message_type_name
					from dbo.BlockedProcessNotificationQueue
				), timeout 10000

				if @@ROWCOUNT = 0
				begin
					rollback;
					break;
				end          



				if not exists -- Checking if it is the poison message
				(
					select * 
					from dbo.PoisonMessages
					where 
						ServiceID = @serviceID and 
						ConversationHandle = @ch and
						MsgTypeName = @MsgType and
						(
							(@Msg is null and Msg is null) or 
							(Msg = @Msg)
						)
				)
				begin
					if @MsgType = N'http://schemas.microsoft.com/SQL/Notifications/EventNotification'
					begin
						select 
							@Report = convert(xml,@Msg)

						select 
							@EventDate = @Report.value('(/EVENT_INSTANCE/StartTime/text())[1]','datetime')
							,@DBID = @Report.value('(/EVENT_INSTANCE/DatabaseID/text())[1]','smallint')
							,@EventType = @Report.value('(/EVENT_INSTANCE/EventType/text())[1]','varchar(128)');
		
						IF @EventType = 'BLOCKED_PROCESS_REPORT'
						begin
							begin try
								select                  
									@Report = @Report.query('/EVENT_INSTANCE/TextData/*');

								select 
									@blockedXML = @Report.query('/blocked-process-report/blocked-process/*')

								-- Merge is not the best option due to overhead of parsing execution plans for long blocking scenarios
								select 
									@resource = @blockedXML.value('/process[1]/@waitresource','varchar(64)') 
									,@blockedXactID = @blockedXML.value('/process[1]/@xactid','bigint') 
									,@waitTime = @blockedXML.value('/process[1]/@waittime','int') 
									,@blockedSPID = @blockedXML.value('process[1]/@spid','smallint') 
									,@blockingSPID = @Report.value('/blocked-process-report[1]/blocking-process[1]/process[1]/@spid','smallint')
									,@blockedSqlHandle = @blockedXML.value('xs:hexBinary(substring((/process[1]/executionStack[1]/frame[1]/@sqlhandle)[1],3))','varbinary(max)') 
									,@blockedStmtStart = isnull(@blockedXML.value('/process[1]/executionStack[1]/frame[1]/@stmtstart','int'), 0) 
									,@blockedStmtEnd = isnull(@blockedXML.value('/process[1]/executionStack[1]/frame[1]/@stmtend','int'), -1);					

								update t
								set t.WaitTime = case when t.WaitTime < @waitTime then @waitTime else t.WaitTime end
								from [dbo].[BlockedProcessesInfo] t
								where 
									t.BlockedSPID = @blockedSPID and
									IsNull(t.BlockedXactId,-1) = isnull(@blockedXactID,-1) and              
									isnull(t.[Resource],'aaa') = isnull(@resource,'aaa') and              
									t.BlockingSPID = @blockingSPID and
									t.BlockedSQLHandle = @blockedSqlHandle and              
									t.BlockedStmtStart = @blockedStmtStart and   
									t.BlockedStmtEnd = @blockedStmtEnd and   
									t.EventDate >= dateadd(millisecond,-@waitTime - 100, @EventDate);

								IF @@rowcount = 0 
								begin
									select 
										@blockingXML = @Report.query('/blocked-process-report/blocking-process/*');

									;with Source
									as
									(
										select 
											repData.BlockedLockMode, repData.BlockedIsolationLevel
											,repData.BlockingStmtStart, repData.BlockingStmtEnd
											,repData.BlockedInputBuf, repData.BlockingStatus
											,repData.BlockingTranCount
											,BlockedSQLText.SQL as BlockedSQL
											,coalesce(blockedERPlan.query_plan,blockedQSPlan.query_plan) AS BlockedQueryPlan
											,coalesce(blockedERPlan.query_hash,blockedQSPlan.query_hash) AS BlockedQueryHash
											,coalesce(blockedERPlan.plan_hash,blockedQSPlan.plan_hash) AS BlockedPlanHash
											,BlockingSQLText.SQL as BlockingSQL
											,repData.BlockingInputBuf
											,coalesce(blockingERPlan.query_plan,blockingQSPlan.query_plan) AS BlockingQueryPlan
										from
											-- Parsing report XML
											(
												select 
													@blockedXML.value('/process[1]/@lockMode','varchar(16)') AS BlockedLockMode
													,@blockedXML.value('/process[1]/@isolationlevel','varchar(32)') AS BlockedIsolationLevel
													,isnull(@blockingXML.value('/process[1]/executionStack[1]/frame[1]/@stmtstart','int'), 0) AS BlockingStmtStart
													,isnull(@blockingXML.value('/process[1]/executionStack[1]/frame[1]/@stmtend','int'), -1) AS BlockingStmtEnd										
													,@blockedXML.value('(/process[1]/inputbuf/text())[1]','nvarchar(max)') AS BlockedInputBuf
													,@blockingXML.value('/process[1]/@status','varchar(16)') AS BlockingStatus
													,@blockingXML.value('/process[1]/@trancount','smallint') AS BlockingTranCount
													,@blockingXML.value('(/process[1]/inputbuf/text())[1]','nvarchar(max)') AS BlockingInputBuf
													,@blockingXML.value('xs:hexBinary(substring((/process[1]/executionStack[1]/frame[1]/@sqlhandle)[1],3))','varbinary(max)') AS BlockingSQLHandle
										
											) as repData 
											-- Getting Query Text					
											outer apply 
												dbo.fnGetSqlText(@blockedSqlHandle,@blockedStmtStart,@blockedStmtEnd) BlockedSQLText
											outer apply 
												dbo.fnGetSqlText(repData.BlockingSQLHandle,repData.BlockingStmtStart,repData.BlockingStmtEnd) BlockingSQLText
											-- Check if statement is still blocked in sys.dm_exec_requests
											outer apply 
												dbo.fnGetQueryInfoFromExecRequests(@collectPlan,@blockedSPID,@blockedSqlHandle,@blockedStmtStart,@blockedStmtEnd) blockedERPlan
											-- if there is no plan handle let's try sys.dm_exec_query_stats
											outer apply
											(
												select plan_hash, query_hash, query_plan
												from dbo.fnGetQueryInfoFromQueryStats(@collectPlan,@blockedSqlHandle,@blockedStmtStart,@blockedStmtEnd,@EventDate,60)
												where blockedERPlan.DataExists is null
											) blockedQSPlan  	

											outer apply 
												dbo.fnGetQueryInfoFromExecRequests(@collectPlan,@blockingSPID,repData.BlockingSQLHandle,repData.BlockingStmtStart, repData.BlockingStmtEnd) blockingERPlan
											-- if there is no plan handle let's try sys.dm_exec_query_stats
											outer apply
											(
												select query_plan
												from dbo.fnGetQueryInfoFromQueryStats(@collectPlan,repData.BlockingSQLHandle,repData.BlockingStmtStart,repData.BlockingStmtEnd,@EventDate,60)
												where blockingERPlan.DataExists is null
											) blockingQSPlan  				               
									) 
									insert into [dbo].[BlockedProcessesInfo](EventDate,DatabaseID,[Resource],WaitTime,BlockedProcessReport,BlockedSPID
											,BlockedXactId,BlockedLockMode,BlockedIsolationLevel,BlockedSQLHandle,BlockedStmtStart
											,BlockedStmtEnd,BlockedSql,BlockedInputBuf,BlockedQueryPlan,BlockingSPID,BlockingStatus
											,BlockingTranCount,BlockingSql,BlockingInputBuf,BlockingQueryPlan
											,BlockedQueryHash,BlockedPlanHash)          
										select @EventDate,@DBID,@resource,@waitTime,@Report,@blockedSPID
											,@blockedXactID,BlockedLockMode,BlockedIsolationLevel,@blockedSqlHandle,@blockedStmtStart
											,@blockedStmtEnd,BlockedSQL,BlockedInputBuf,BlockedQueryPlan
											,@blockingSPID,BlockingStatus,BlockingTranCount
											,BlockingSQL,BlockingInputBuf,BlockingQueryPlan
											,BlockedQueryHash,BlockedPlanHash
										from Source
									option (maxdop 1);
								end	
							end try
							begin catch
								select
									@ErrorMsg = error_message()
									,@ErrorLine = error_line()
									,@ReportMsg = convert(nvarchar(max),@Report);

								if XACT_STATE() = -1 -- uncommittable transaction
								begin
									set @IsPoisonMsg = 1;
									rollback;

									insert into dbo.PoisonMessages(ServiceID,ConversationHandle,MsgTypeName,Msg,ErrorLine,ErrorMsg)
									values(@serviceID,@ch,@MsgType,@Msg,@ErrorLine,@ErrorMsg);
								end
								else begin
									set @IsPoisonMsg = 0;
									insert into dbo.BlockedProcessesInfo(EventDate, BlockedProcessReport)
									values(@EventDate,@Report);
								end;
								
								exec dbo.BMFrameworkErrorNotification
									@Module = @Module, @IsPoisonMsg = @IsPoisonMsg, @ErrorMsg = @ErrorMsg, @ErrorLine = @ErrorLine, @Report = @ReportMsg;
							end catch
						end -- @EventType = BLOCKED_PROCESS_REPORT
					end -- @MsgType = http://schemas.microsoft.com/SQL/Notifications/EventNotification
					else if @MsgType = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
						end conversation @ch;
					-- else handle errors here			
			end
			while @@TRANCOUNT > 0
				commit;
		end try
		begin catch				    
			-- capture info about error message here      
			if @@trancount > 0
				rollback;
	
			select
				@ErrorMsg = error_message()
				,@ErrorLine = error_line()
				,@ReportMsg = 'Outer catch block';
							
			exec dbo.BMFrameworkErrorNotification
				@Module = @Module, @IsPoisonMsg = 1, @ErrorMsg = @ErrorMsg, @ErrorLine = @ErrorLine, @Report = @ReportMsg;

			-- Using raiserror instead of throw for SS2008 compatibility;
			raiserror(@ErrorMsg,16,1);
			break;
		end catch
	end
end
go    

create procedure [dbo].[SB_DeadlockEvent_Activation]
with execute as owner
/****************************************************************************/
/* Proc: dbo.SB_DeadlockEvent_Activation                                    */
/* Author: Dmitri V. Korotkevitch                                           */
/*                                                                          */
/* Purpose:                                                                 */ 
/*    Activation stored procedure for Deadlock Event Notification           */
/*                                                                          */
/* Version History:                                                         */ 
/*     v1.0 2018-08-01. Initial implementation                              */
/****************************************************************************/
as
begin
	set nocount on
    
	declare
		@Msg varbinary(max)
		,@serviceID int
		,@ch uniqueidentifier
		,@MsgType sysname      
		,@Report xml
		,@EventDate datetime
		,@DeadlockID int
		,@EventType varchar(128)
		,@collectPlan bit = 1 -- Controls if we collect execution plans

	declare
		@Module sysname = object_name(@@PROCID)
		,@ErrorMsg nvarchar(256) 
		,@ErrorLine int
		,@ReportMsg nvarchar(max)
		,@IsPoisonMsg bit

    if exists
	(
		select * 
		from dbo.BMFrameworkConfig
		where [Key] = 'CollectPlanFromDeadlockGraph' and [Value] = '0'
	)
		set @collectPlan = 0;

	declare
		@Victims table
		(
			Victim sysname not null primary key
		)		  
	
	while 1 = 1
	begin
		begin try
			begin tran
				-- for simplicity sake we are processing data in one-by-one facion      
				-- rather than load everything to the temporary
				-- table variable
				waitfor 
				(
					receive top (1)
						@serviceID = service_id
						,@ch = conversation_handle
						,@Msg = message_body
						,@MsgType = message_type_name
					from dbo.DeadlockNotificationQueue
				), timeout 10000

				if @@ROWCOUNT = 0
				begin
					rollback;
					break;
				end          

				if not exists -- Checking if it is the poison message
				(
					select * 
					from dbo.PoisonMessages
					where 
						ServiceID = @serviceID and 
						ConversationHandle = @ch and
						MsgTypeName = @MsgType and
						(
							(@Msg is null and Msg is null) or 
							(Msg = @Msg)
						)
				)
				begin
					if @MsgType = N'http://schemas.microsoft.com/SQL/Notifications/EventNotification'
					begin
						select 
							@Report = convert(xml,@Msg)

						select 
							@EventDate = @Report.value('(/EVENT_INSTANCE/PostTime/text())[1]','datetime')
							,@EventType = @Report.value('(/EVENT_INSTANCE/EventType/text())[1]','varchar(128)');
		
						IF @EventType = 'DEADLOCK_GRAPH'
						begin
							set @Report = @Report.query('/EVENT_INSTANCE/TextData/*');

							begin try
								insert into dbo.Deadlocks(EventDate,DeadlockGraph)
								values(@EventDate, @Report);
								set @DeadlockID = SCOPE_IDENTITY();

								-- In majority of cases, we will have single-victim deadlock. However, we need to support
								-- the cases when we may have multiple victims
								delete from @Victims;

								;with Victim(victim) as ( select @Report.value('/deadlock-list[1]/deadlock[1]/@victim','sysname') )
								insert into @Victims(Victim) 
									select victim 
									from Victim
									where victim is not null;

								if @@rowcount = 0 -- Multiple victims
									insert into @Victims(Victim) 
										select distinct v.p.value('@id','sysname') 
										from @Report.nodes('/deadlock-list[1]/deadlock[1]/victim-list[1]/victimProcess') as v(p);

								;with ProcessInfo(Process,SPID,DatabaseID,[Resource],LockMode,WaitTime,TranCount
								,IsolationLevel,ProcName,Line,SQLHandle,StmtStart,StmtEnd,InputBuf,SQLFromFrame)
								as
								(
									select 
										d.p.value('./@id','sysname')
										,d.p.value('./@spid','smallint') 
										,d.p.value('./@currentdb','smallint') 
										,d.p.value('./@waitresource','varchar(64)') 
										,d.p.value('./@lockMode','varchar(16)') 
										,d.p.value('./@waittime','int') 
										,d.p.value('./@trancount','smallint') 
										,d.p.value('./@isolationlevel','varchar(32)')
										,d.p.value('./executionStack[1]/frame[1]/@procname','sysname')
										,d.p.value('./executionStack[1]/frame[1]/@line','int')
										,d.p.value('xs:hexBinary(substring((./executionStack[1]/frame[1]/@sqlhandle)[1],3))','varbinary(max)') 
										,isnull(d.p.value('./executionStack[1]/frame[1]/@stmtstart','int'), 0)
										,isnull(d.p.value('./executionStack[1]/frame[1]/@stmtend','int'), -1) 	
										,d.p.value('(./inputbuf/text())[1]','nvarchar(max)')
										,d.p.value('(./executionStack[1]/frame[1]/text())[1]','nvarchar(max)')
									from 
										@Report.nodes('/deadlock-list[1]/deadlock[1]/process-list[1]/process') as d(p)
								)
								insert into dbo.DeadlockProcesses(EventDate,DeadlockID,Process,IsVictim,SPID,DatabaseID
									,[Resource],LockMode,WaitTime,TranCount,IsolationLevel,ProcName,Line,SQLHandle
									,QueryHash,PlanHash,StmtStart,StmtEnd,[Sql],InputBuf,QueryPlan)
									select @EventDate,@DeadlockID,p.Process,vic.IsVictim,p.SPID,p.DatabaseID
										,p.[Resource],p.LockMode,p.WaitTime,p.TranCount,p.IsolationLevel,p.ProcName,p.Line
										,p.SQLHandle, QP.query_hash, QP.plan_hash, p.StmtStart,p.StmtEnd
										,SQLText.[SQL],p.InputBuf,QP.query_plan
									from 
										ProcessInfo p
											cross apply
											(
												select 
													case 
														when exists(select * from @Victims v where v.Victim = p.Process)
														then 1
														else 0
													end as IsVictim
											) vic
											cross apply
											(
												select
													case 
														when (isnull(ltrim(rtrim(p.SQLFromFrame)),'') <> '') or isnulL(p.SQLHandle,0x) = 0x 
														then ltrim(rtrim(p.SQLFromFrame))
														else 
														(
															select SQL 
															from dbo.fnGetSqlText(p.SQLHandle, p.StmtStart, p.StmtEnd)
														)
													end as [SQL]
											) SQLText
											outer apply
												dbo.fnGetQueryInfoFromQueryStats(@collectPlan,p.SQLHandle,p.StmtStart,p.StmtEnd,@EventDate,60) QP;
							end try
							begin catch
								select
									@ErrorMsg = error_message()
									,@ErrorLine = error_line()
									,@ReportMsg = convert(nvarchar(max),@Report);

								if XACT_STATE() = -1 -- uncommittable transaction
								begin
									set @IsPoisonMsg = 1;
									rollback;

									insert into dbo.PoisonMessages(ServiceID,ConversationHandle,MsgTypeName,Msg,ErrorLine,ErrorMsg)
									values(@serviceID,@ch,@MsgType,@Msg,@ErrorLine,@ErrorMsg);
								end
								else
									set @IsPoisonMsg = 0;


								
								exec dbo.BMFrameworkErrorNotification
									@Module = @Module, @IsPoisonMsg = @IsPoisonMsg, @ErrorMsg = @ErrorMsg, @ErrorLine = @ErrorLine, @Report = @ReportMsg;
							end catch
						end -- @EventType = DEADLOCK_GRAPH
					end -- @MsgType = http://schemas.microsoft.com/SQL/Notifications/EventNotification
					else if @MsgType = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
						end conversation @ch;
				end
			while @@TranCount > 0
				commit;
		end try
		begin catch					      
			-- capture info about error message here      
			if @@trancount > 0
				rollback;
			
			select
				@ErrorMsg = error_message()
				,@ErrorLine = error_line()
				,@ReportMsg = 'Outer catch block'
							
				exec dbo.BMFrameworkErrorNotification
					@Module = @Module, @IsPoisonMsg = 1, @ErrorMsg = @ErrorMsg, @ErrorLine = @ErrorLine, @Report = @ReportMsg;
			-- Using raiserror instead of throw for SS2008 compatibility;
			raiserror(@ErrorMsg,16,1);
			break;
		end catch
	end
end
go    
