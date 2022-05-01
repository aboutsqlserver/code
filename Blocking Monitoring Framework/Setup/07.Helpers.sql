/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                              Initial Setup                               */
/*                        Creating Helpers Objects							*/
/****************************************************************************/

use DBA
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'PurgeBlockingInfo') drop proc dbo.PurgeBlockingInfo;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'BMFrameworkPartitionMaintenance') drop proc dbo.BMFrameworkPartitionMaintenance;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'PurgeDeadlockInfo') drop proc dbo.PurgeDeadlockInfo;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'PurgePoisonMessages') drop proc dbo.PurgePoisonMessages;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'BMFrameworkQueuesCheck') drop proc dbo.BMFrameworkQueuesCheck;
go

create proc dbo.PurgeBlockingInfo
(
	@RetentionDays int
)
/****************************************************************************/
/* Proc: dbo.PurgeBlockingInfo                                              */
/* Author: Dmitri V. Korotkevitch                                           */
/*                                                                          */
/* Purpose:                                                                 */ 
/*    Purge blocking information based on retention interval defined by     */
/*    @RetentionDays parameter. This SP is recommended for non-partitioned  */
/*    data storage. Partitioned version should use                          */ 
/*    dbo.PurgeBMFrameworkDataPartitioned instead                           */
/*                                                                          */
/* Return Codes   :                                                         */ 
/*    -1: Invalid @RetentionDays value                                      */
/*     0: Data has been purged                                              */
/*                                                                          */
/* Version History:                                                         */ 
/*     v1.0 2018-08-01. Initial implementation                              */
/****************************************************************************/
as
begin
	set xact_abort, nocount on

	if @RetentionDays <= 0
	begin
		raiserror('PurgeBlockingInfo: @RetentionDays parameter should be positive. Current value: %d',16,1,@RetentionDays);
		return -1;
	end;

	delete from dbo.BlockedProcessesInfo where EventDate < dateadd(day,-@RetentionDays,convert(date,getdate()));
	return 0;
end;
go

create proc dbo.PurgeDeadlockInfo
(
	@RetentionDays int
)
/****************************************************************************/
/* Proc: dbo.PurgeDeadlockInfo                                              */
/* Author: Dmitri V. Korotkevitch                                           */
/*                                                                          */
/* Purpose:                                                                 */ 
/*    Purge deadlock information based on retention interval defined by     */
/*    @RetentionDays parameter. This SP is recommended for non-partitioned  */
/*    data storage. Partitioned version should use                          */ 
/*    dbo.PurgeBMFrameworkDataPartitioned instead                           */
/*                                                                          */
/* Return Codes   :                                                         */ 
/*    -1: Invalid @RetentionDays value                                      */
/*     0: Data has been purged                                              */
/*                                                                          */
/* Version History:                                                         */ 
/*     v1.0 2018-08-01. Initial implementation                              */
/****************************************************************************/
as
begin
	set xact_abort, nocount on

	if @RetentionDays <= 0
	begin
		raiserror('PurgeDeadlockInfo: @RetentionDays parameter should be positive. Current value: %d',16,1,@RetentionDays);
		return -1;
	end;
	
	begin tran
		delete from dbo.DeadlockProcesses where EventDate < dateadd(day,-@RetentionDays,convert(date,getdate()));
		delete from dbo.Deadlocks where EventDate < dateadd(day,-@RetentionDays,convert(date,getdate()));;
	commit;
	return 0;
end;
go

create proc dbo.PurgePoisonMessages
(
	@RetentionDays int = 1
)
/****************************************************************************/
/* Proc: dbo.PurgePoisonMessages                                            */
/* Author: Dmitri V. Korotkevitch                                           */
/*                                                                          */
/* Purpose:                                                                 */ 
/*    Purge poison messages information based on retention interval defined */
/*    by @RetentionDays parameter. This SP is recommended for non-partitioned*/
/*    data storage. Partitioned version should use                          */ 
/*    dbo.BMFrameworkPartitionMaintenance instead                           */
/*                                                                          */
/* Return Codes   :                                                         */ 
/*    -1: Invalid @RetentionDays value                                      */
/*     0: Data has been purged                                              */
/*                                                                          */
/* Version History:                                                         */ 
/*     v1.0 2018-08-01. Initial implementation                              */
/****************************************************************************/
as
begin
	set xact_abort, nocount on

	if @RetentionDays < 0
	begin
		raiserror('PurgePoisonMessages: @RetentionDays parameter should be >= 0. Current value: %d',16,1,@RetentionDays);
		return -1;
	end;
	
	if @RetentionDays = 0
		truncate table dbo.PoisonMessages;
	else 
		while 1 = 1
		begin
			;with CTE
			as
			(
				select top 1000 ServiceID, ConversationHandle, EventDate
				from dbo.PoisonMessages
				order by EventDate
			)
			delete from t
			from CTE c inner loop join dbo.PoisonMessages t on
				c.ServiceID = t.ServiceID and 
				c.ConversationHandle = t.ConversationHandle and
				c.EventDate = t.EventDate
			option (maxdop 1);

			if @@ROWCOUNT < 1000
				break;
		end
	return 0;
end;
go

create proc dbo.BMFrameworkPartitionMaintenance 
(
	@RetentionWeeks int = 8
)
/****************************************************************************/
/* Proc: dbo.BMFrameworkPartitionMaintenance                                */
/* Author: Dmitri V. Korotkevitch                                           */
/*                                                                          */
/* Purpose:                                                                 */ 
/*    Purge blocking and deadlock information based on retention interval   */
/*    defined by @RetentionWeeks parameter. This SP is recommended for      */ 
/*    partitioned data storage. Ideally, should be setup running as         */
/*    SQL Agent job running on Sundays.                                     */
/*                                                                          */
/* Change Filegroup in ALTER PARTITION SCHEME if you store the data on      */
/* different filegroup than PRIMARY                                         */
/*                                                                          */
/* Return Codes:                                                            */                       
/*    -2: SP cannot run in the transaction                                  */
/*    -1: Invalid @RetentionDays value                                      */
/*     0: Data has been purged                                              */
/*                                                                          */
/* Version History:                                                         */ 
/*     v1.0 2018-08-01. Initial implementation                              */
/****************************************************************************/
as
begin
	set xact_abort, nocount on
	set deadlock_priority 10

	declare
		@PFName sysname = 'pfBMFramework'
		,@CurrentDate date = getdate() -- Current Date
		,@PartitionDate date = dateadd(week,datediff(week,'2018-08-03',getdate()),'2018-08-03') -- find last Sunday
		,@PreallocatedWeeks int = 2 -- How many weeks we want to pre-allocate
		,@PurgeDate date -- Last parition value we want to keep
		,@MaxSplitDate date -- Date that corresponds to @PreallocatedWeeks
		,@BoundaryValue date
		,@Msg nvarchar(256)

	if @RetentionWeeks <= 0
	begin
		raiserror('PurgeBMFrameworkDataPartitioned: @@RetentionWeeks parameter should be positive. Current value: %d',16,1,@RetentionWeeks);
		return -1;
	end;

	if @@TRANCOUNT > 0
	begin
		raiserror('dbo.PurgeBMFrameworkDataPartitioned procedure cannot run within a transaction',16,1);
		return -2;
	end;

	select
		@PurgeDate = dateadd(week, -1 * @RetentionWeeks, @PartitionDate)
		,@MaxSplitDate = dateadd(week, @PreallocatedWeeks + 1, @PartitionDate);
	
	-- First, we will create new partitions
	select @BoundaryValue = convert(date, max(r.value))
	from 
		sys.partition_functions pf inner join sys.partition_range_values r on 
			pf.function_id = r.function_id
	where pf.name = @PFName;

	if @BoundaryValue < @CurrentDate
		set @BoundaryValue = @PartitionDate;

	set @Msg = 
		'@MaxSplitDate: ' + convert(varchar(10), @MaxSplitDate, 121) + 
		'; @BoundaryValue: ' + convert(varchar(10),  @BoundaryValue, 121);
	raiserror('%s',0,1,@Msg) with nowait;

	while @BoundaryValue < @MaxSplitDate
	begin
		set @BoundaryValue = DATEADD(WEEK, 1, @BoundaryValue);

		set @Msg = 
			'Creating the new partition with value: ' + convert(varchar(10),  @BoundaryValue, 121);
		raiserror('%s',0,1,@Msg) with nowait;

		begin tran
			alter partition scheme psBMFramework next used [PRIMARY];
			alter partition function pfBMFramework() split range(@BoundaryValue);
		commit
	end

	-- Next, we will purge
	set @Msg = 
		'Starting purge. @PurgeDate: ' + convert(varchar(10), @PurgeDate, 121);
	raiserror('%s',0,1,@Msg) with nowait;

	select @BoundaryValue = convert(date, min(r.value))
	from 
		sys.partition_functions pf inner join sys.partition_range_values r on 
			pf.function_id = r.function_id
	where pf.name = @PFName;

	while 1 = 1 
	begin
		set @BoundaryValue = null;

		select @BoundaryValue = convert(date, min(r.value))
		from 
			sys.partition_functions pf inner join sys.partition_range_values r on 
				pf.function_id = r.function_id
		where 
			pf.name = @PFName and 
			convert(date, r.value) <= @PurgeDate;
		
		if @BoundaryValue is null
			break;
		
		truncate table dbo.BlockedProcessesInfoTmp;
		truncate table dbo.DeadlocksTmp;
		truncate table dbo.DeadlockProcessesTmp;
		truncate table dbo.PoisonMessagesTmp;
		
		set @Msg = 
			'Truncating partition: ' + convert(varchar(10), @BoundaryValue, 121);
		raiserror('%s',0,1,@Msg) with nowait;

		begin tran
			alter table dbo.BlockedProcessesInfo switch partition 1 to dbo.BlockedProcessesInfoTmp;
			alter table dbo.Deadlocks switch partition 1 to dbo.DeadlocksTmp;
			alter table dbo.DeadlockProcesses switch partition 1 to dbo.DeadlockProcessesTmp;
			alter table dbo.PoisonMessages switch partition 1 to dbo.PoisonMessagesTmp;
	
			alter partition function pfBMFramework() merge range(@BoundaryValue)
		commit
	
		truncate table dbo.BlockedProcessesInfoTmp;
		truncate table dbo.DeadlocksTmp;
		truncate table dbo.DeadlockProcessesTmp;
	end;
	raiserror('Purge successfully completed',0,1) with nowait;

	return 0;
end;
go

create proc [dbo].[BMFrameworkQueuesCheck]
/****************************************************************************/
/* Proc: dbo.BMFrameworkQueuesCheck                                         */
/* Author: Dmitri V. Korotkevitch                                           */
/*                                                                          */
/* Purpose:                                                                 */ 
/*    Checkign that SB Queues are enabled. Can be run as SQL Agent Job      */
/*                                                                          */
/* Version History:                                                         */ 
/*     v1.0 2018-08-01. Initial implementation                              */
/****************************************************************************/
as
begin
	set nocount on

	if
	(
		select count(*)
		from sys.service_queues
		where name in ('BlockedProcessNotificationQueue', 'DeadlockNotificationQueue') AND is_receive_enabled = 1
	) < 2
	begin
		declare
			@MailStatus int
			,@Recipient varchar(255) = '<recipients>'
			,@Subject nvarchar(255) = 'Blocking Monitoring Service Queues - Disabled'
			,@Body nvarchar(255) = 'Blocking Monitoring Service Queues are not enabled on ' + @@SERVERNAME

		exec @MailStatus = msdb.dbo.sp_send_dbmail
			@recipients = @Recipient, @subject = @Subject, @body = @Body

		if @MailStatus <> 0
			raiserror('Unable to Send DB Mail', 16, 1)
	end
end
go
