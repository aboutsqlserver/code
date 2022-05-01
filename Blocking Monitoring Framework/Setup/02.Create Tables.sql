/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                              Initial Setup                               */
/*                           Creating the Tables                            */
/****************************************************************************/

use DBA
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'CheckVersion') drop proc dbo.CheckVersion;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'SetVersion') drop proc dbo.SetVersion;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Versions') drop table dbo.Versions;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'BMFrameworkConfig') drop table dbo.BMFrameworkConfig;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'BlockedProcessesInfo') drop table dbo.BlockedProcessesInfo;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Deadlocks') drop table dbo.Deadlocks;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'DeadlockProcesses') drop table dbo.DeadlockProcesses;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'BlockedProcessesInfoTmp') drop table dbo.BlockedProcessesInfoTmp;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'DeadlocksTmp') drop table dbo.DeadlocksTmp;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'DeadlockProcessesTmp') drop table dbo.DeadlockProcessesTmp;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'PoisonMessages') drop table dbo.PoisonMessages;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'PoisonMessagesTmp') drop table dbo.PoisonMessagesTmp;
go

create table dbo.Versions
(
	Product sysname not null,
	Version varchar(32) not null,
	CreatedDate datetime not null
		constraint DEF_Versions_CreatedDate
		default getdate(),
	LastAppliedDate datetime not null
		constraint DEF_Versions_LastAppliedDate
		default getdate(),
	constraint PK_Versions
	primary key clustered(Product)
);
go

create proc dbo.CheckVersion
( 
	@Product sysname
	,@Version varchar(32)
)
as
begin
	set nocount, xact_abort on

	declare
		@CurrVersion varchar(32) = 'NULL'

	select @CurrVersion = IsNull(Version,'NULL') from dbo.Versions where Product = @Product;

	if @CurrVersion <> @Version
	begin
		raiserror('Incorrent %s version. Expected: %s. Actual: %s',20,1,@Product,@Version,@CurrVersion) with log;
		return -1;
	end
	raiserror('Product %s version has been validated. Current version: %s',0,1,@Product,@CurrVersion) with nowait;
	return 0;
end
go

create proc dbo.SetVersion
( 
	@Product sysname
	,@Version varchar(32)
)
as
begin
	merge into  dbo.Versions as T
	using (select @Product as Product, @Version as Version) as S
	on T.Product = S.Product
	when not matched by target then
		insert(Product,Version) values(S.Product,S.Version)
	when matched then
		update set LastAppliedDate = getdate();
end
go

create table dbo.BMFrameworkConfig
(
	[Key] varchar(64) not null,
	[Value] varchar(256) not null,

	constraint PK_BMFrameworkConfig
	primary key clustered([Key])
)
go

insert into dbo.BMFrameworkConfig([Key],[Value]) values('CollectPlanFromBlockingReport','1');
insert into dbo.BMFrameworkConfig([Key],[Value]) values('CollectPlanFromDeadlockGraph','1');
go

create table dbo.BlockedProcessesInfo
(
	ID int not null identity(1,1),
	EventDate datetime not null,
	-- ID of the database where locking occurs
	DatabaseID smallint null,
	-- Blocking resource
	[Resource] varchar(64) null,
	-- Wait time in MS
	WaitTime int null,
	-- Raw blocked process report
	BlockedProcessReport xml null,
	-- SPID of the blocked process
	BlockedSPID smallint null,
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
	-- Blocked Query Hash
	BlockedQueryHash binary(8) null,
	-- Blocked Query Plan Hash
	BlockedPlanHash binary(8) null,
	-- Blocked SQL based on SQL Handle
	BlockedSql nvarchar(max) null,
	-- Blocked InputBuf from the report
	BlockedInputBuf nvarchar(max) null, 
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
	BlockingQueryPlan xml null
);

create table dbo.Deadlocks
(
	EventDate datetime not null,
	DeadlockID int not null identity(1,1),
	DeadlockGraph xml not null,
);
go

create table dbo.DeadlockProcesses
(
	EventDate datetime not null,
	DeadlockID int not null,
	Process sysname null,
	IsVictim bit not null,	
	-- SPID of the process
	SPID smallint null,
	-- ID of the database where deadlock occured
	DatabaseID smallint null,
	-- Blocking resource
	[Resource] varchar(64) null,
	-- Lock Mode
	LockMode varchar(16) null,
	-- Wait time in MS
	WaitTime int null,
	-- Tran Count
	TranCount smallint null,	
	-- Transaction isolation level for the process
	IsolationLevel varchar(32) null,
	-- Top ProcName from execution stack
	ProcName sysname null,
	-- Top Line from execution stack
	Line sysname null,
	-- Top SQL Handle from execution stack
	SQLHandle varbinary(64) null,
	-- Query Hash
	QueryHash binary(8) null,
	-- Blocked Query Plan Hash
	PlanHash binary(8) null,
	-- SQL Statement Start offset
	StmtStart int null,
	-- SQL Statement End offset
	StmtEnd int null,
	-- SQL based on frame data and/or SQL Handle
	[Sql] nvarchar(max) null,
	-- InputBuf from the report
	InputBuf nvarchar(max) null, 
	-- Query Plan based on SQL Handle
	QueryPlan xml null,
);
go

create table dbo.PoisonMessages
(
	EventDate datetime not null
		constraint PK_PoisonMessages_EventDate
		default getdate(),
	ServiceID int not null,
	ConversationHandle uniqueidentifier not null,
	MsgTypeName sysname not null,
	Msg varbinary(max) null,
	ErrorLine int null,
	ErrorMsg nvarchar(max) null
);
go


alter table dbo.BlockedProcessesInfo set (lock_escalation=disable);
alter table dbo.Deadlocks set (lock_escalation=disable);
alter table dbo.DeadlockProcesses set (lock_escalation=disable);
alter table dbo.PoisonMessages set (lock_escalation=disable);
go

-- Indexing tables. We will partition the tables on weekly basis if it is supported
-- You may change the filegroups if needed

-- You may need to create other indexes for analysis queries depending on how you are planning
-- to analyze and aggregate the data
declare
	@EngineEdition int = convert(int, serverproperty('EngineEdition')) -- 3 means Enterprise
	,@EngineVersion int = convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) 

if 
	(@EngineEdition = 3) or -- Enterprise / Developer
	(@EngineVersion > 13) or -- SQL Server 2017+
	(@EngineVersion = 13 and left(convert(varchar(64),serverproperty('productlevel')),2) = 'SP') -- SQL Server 2016 with SP	
begin
	raiserror('Partitioning is supported',0,1) with nowait;

	if exists(select * from sys.partition_schemes where name = 'psBMFramework') drop partition scheme psBMFramework;
	if exists(select * from sys.partition_functions where name = 'pfBMFramework') drop partition function pfBMFramework;
	 	
	declare
		@sql nvarchar(max)
		,@firstDate datetime = dateadd(week,datediff(week,'2018-06-03',getdate()),'2018-06-03') -- find last Sunday
 
	set @sql = N'

create partition function pfBMFramework(datetime) 
as range right for values
(''' + convert(nvarchar(10),@firstDate,121) + ''',''' +   
+ convert(nvarchar(10),dateadd(week,1,@firstDate),121) + ''',''' +   
+ convert(nvarchar(10),dateadd(week,2,@firstDate),121) + N''');

create partition scheme psBMFramework as partition pfBMFramework all to ([PRIMARY]);

';
	raiserror('Executing: %s',0,1,@sql) with nowait;
	exec sp_executesql @sql;

	create unique clustered index IDX_BlockedProcessInfo_EventDate_ID
	on dbo.BlockedProcessesInfo(EventDate, ID)
	with (data_compression=page)
	on psBMFramework(EventDate);

	create unique clustered index IDX_Deadlocks_EventDate_DeadlockID
	on dbo.Deadlocks(EventDate, DeadlockID)
	with (data_compression=row)
	on psBMFramework(EventDate);

	create unique clustered index IDX_DeadlockProcesses_EventDate_DeadlockID_Process
	on dbo.DeadlockProcesses(EventDate, DeadlockID,Process)
	with (data_compression=page)
	on psBMFramework(EventDate);

	create clustered index IDX_PoisonMessages_ServiceID_ConversationHandle
	on dbo.PoisonMessages(ServiceID, ConversationHandle, EventDate)
	on psBMFramework(EventDate);

	-- Creating tables for sliding window purge
	create table dbo.BlockedProcessesInfoTmp
	(
		ID int not null,
		EventDate datetime not null,
		DatabaseID smallint null,
		[Resource] varchar(64) null,
		WaitTime int null,
		BlockedProcessReport xml null,
		BlockedSPID smallint null,
		BlockedXactId bigint null,
		BlockedLockMode varchar(16) null,
		BlockedIsolationLevel varchar(32) null,
		BlockedSQLHandle varbinary(64) null,
		BlockedStmtStart int null,
		BlockedStmtEnd int null,
		BlockedQueryHash binary(8) null,
		BlockedPlanHash binary(8) null,
		BlockedSql nvarchar(max) null,
		BlockedInputBuf nvarchar(max) null, 
		BlockedQueryPlan xml null,
		BlockingSPID smallint null,
		BlockingStatus varchar(16) null,
		BlockingTranCount int null, 
		BlockingInputBuf nvarchar(max) null,
		BlockingSql nvarchar(max) null,
		BlockingQueryPlan xml null
	);

	create table dbo.DeadlocksTmp
	(
		EventDate datetime not null,
		DeadlockID int not null,
		DeadlockGraph xml not null,
	);

	create table dbo.DeadlockProcessesTmp
	(
		EventDate datetime not null,
		DeadlockID int not null,
		Process sysname null,
		IsVictim bit not null,	
		SPID smallint null,
		DatabaseID smallint null,
		[Resource] varchar(64) null,
		LockMode varchar(16) null,
		WaitTime int null,
		TranCount smallint null,	
		IsolationLevel varchar(32) null,
		ProcName sysname null,
		Line sysname null,
		SQLHandle varbinary(64) null,
		QueryHash binary(8) null,
		PlanHash binary(8) null,
		StmtStart int null,
		StmtEnd int null,
		[Sql] nvarchar(max) null,
		InputBuf nvarchar(max) null, 
		QueryPlan xml null
	);

	create table dbo.PoisonMessagesTmp
	(
		EventDate datetime not null,
		ServiceID int not null,
		ConversationHandle uniqueidentifier not null,
		MsgTypeName sysname not null,
		Msg varbinary(max) null,
		ErrorLine int null,
		ErrorMsg nvarchar(max) null
	);

	create unique clustered index IDX_BlockedProcessInfo_EventDate_ID
	on dbo.BlockedProcessesInfoTmp(EventDate, ID)
	with (data_compression=page);

	create unique clustered index IDX_Deadlocks_EventDate_DeadlockID
	on dbo.DeadlocksTmp(EventDate, DeadlockID)
	with (data_compression=row);

	create unique clustered index IDX_DeadlockProcesses_EventDate_DeadlockID_Process
	on dbo.DeadlockProcessesTmp(EventDate, DeadlockID,Process)
	with (data_compression=page);

	create clustered index IDX_PoisonMessages_ServiceID_ConversationHandle
	on dbo.PoisonMessagesTmp(ServiceID, ConversationHandle, EventDate);

	raiserror('Setup Partition Management Job using SPs from 07.Helpers.sql script',0,1) with nowait;
end
else begin
	raiserror('Partitioning is not supported',0,1) with nowait;
	
	create unique clustered index IDX_BlockedProcessInfo_EventDate_ID
	on dbo.BlockedProcessesInfo(EventDate, ID);

	create unique clustered index IDX_Deadlocks_EventDate_DeadlockID
	on dbo.Deadlocks(EventDate, DeadlockID);

	create unique clustered index IDX_DeadlockProcesses_EventDate_DeadlockID_Process
	on dbo.DeadlockProcesses(EventDate, DeadlockID,Process);

	create clustered index IDX_PoisonMessages_ServiceID_ConversationHandle
	on dbo.PoisonMessages(ServiceID, ConversationHandle);

	create nonclustered index IDX_PoisonMessages_EventDate
	on dbo.PoisonMessages(EventDate);
end
go
