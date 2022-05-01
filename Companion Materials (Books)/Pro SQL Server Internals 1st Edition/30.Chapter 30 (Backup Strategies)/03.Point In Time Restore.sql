/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*               Chapter 30. Designing a Backup Strategy                    */
/*                         Point In Time Restore                            */
/****************************************************************************/
set noexec off
go


if not exists 
( 
	select	*
	from	sys.databases
	where	name = 'BackupRestoreDemo' ) 
	begin
		raiserror('You need to create BackupRestoreDemo DB with "01.Create Test DB.sql" script',16,1)
		set noexec on
	end
go

use BackupRestoreDemo
go


if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Invoices'    
)
	drop table dbo.Invoices
go

create table dbo.Invoices
(
	InvoiceId int not null
);

insert into dbo.Invoices values(1)
insert into dbo.Invoices values(2)
insert into dbo.Invoices values(3) 
go

use master
go

-- Full backup
backup database BackupRestoreDemo 
to disk = N'BackupRestoreDemo.bak' 
with format, init,  
name = N'BackupRestoreDemo-Full Database Backup', 
stats = 5, checksum
 --, COMPRESSION
go

-- 15 seconds delay
waitfor delay '00:00:15.000'
go

-- Dropping table
drop table BackupRestoreDemo.dbo.Invoices
go

-- 15 seconds delay
waitfor delay '00:00:15.000'
go

/* Point in time recovery */

-- Step 1 Backing up the log if it was not backed up

-- Tran Log Backup
backup log BackupRestoreDemo 
to disk = N'BackupRestoreDemo.trn' 
with format, init,  
name = N'BackupRestoreDemo-Transaction Log Backup', 
stats = 5, checksum
 --, COMPRESSION
go

/*** Approach 1: Using default trace ***/
declare
	@TraceFilePath nvarchar(2000)

select @TraceFilePath  = convert(nvarchar(2000),value)
from ::fn_trace_getinfo(0) 
where traceid = 1 and property = 2

select
	StartTime
	,EventClass
	,case EventSubClass 
		when 0 then 'DROP' 
		when 1 then 'COMMIT'
		when 2 then 'ROLLBACK'
	end as SubClass
	,ObjectID
	,ObjectName
	,TransactionID
from ::fn_trace_gettable(@TraceFilePath, default)
where EventClass = 47 and DatabaseName = 'BackupRestoreDemo'
order by StartTime desc
go

-- Restoring Database 
restore database [BackupRestoreDemoCopy] 
from disk = N'BackupRestoreDemo.bak' 
with file = 1,  
move N'BackupRestoreDemo' to N'c:\db\BackupRestoreDemoCopy.mdf',  
move N'BackupRestoreDemo_Entities' to N'c:\db\BackupRestoreDemoCopy_Enttities.ndf',  
move N'BackupRestoreDemo_Operational' to N'c:\db\BackupRestoreDemoCopy_Operational.ndf',  
move N'BackupRestoreDemo_Historical' to N'c:\db\BackupRestoreDemoCopy_Historical.ndf',  
move N'BackupRestoreDemo_log' to N'c:\db\BackupRestoreDemoCopy_log.ldf',  
norecovery,  nounload,  stats = 5;
go

-- Transaction Log restore
restore log [BackupRestoreDemoCopy] 
from disk = N'BackupRestoreDemo.trn' 
with nounload, norecovery, stats = 10,
stopat = N'<Insert Time Here>';
go

restore database [BackupRestoreDemoCopy] with recovery;
go

select * from BackupRestoreDemoCopy.dbo.Invoices
go

drop database [BackupRestoreDemoCopy]
go

/*** Approach 2: Analyzing Log Records ***/
select [Current LSN], [Begin Time], Operation, [Transaction Name], [Description]
from fn_dump_dblog
(
default, default, default, default, 'BackupRestoreDemo.trn',
default, default, default, default, default, default, 
default, default, default, default, default, default, 
default, default, default, default, default, default, 
default, default, default, default, default, default, 
default, default, default, default, default, default, 
default, default, default, default, default, default, 
default, default, default, default, default, default, 
default, default, default, default, default, default, 
default, default, default, default, default, default, 
default, default, default, default, default, default, 
default, default, default)
where [Transaction Name] = 'DROPOBJ'
go

restore database [BackupRestoreDemoCopy] 
from disk = N'BackupRestoreDemo.bak' 
with file = 1,  
move N'BackupRestoreDemo' to N'c:\db\BackupRestoreDemoCopy.mdf',  
move N'BackupRestoreDemo_Entities' to N'c:\db\BackupRestoreDemoCopy_Enttities.ndf',  
move N'BackupRestoreDemo_Operational' to N'c:\db\BackupRestoreDemoCopy_Operational.ndf',  
move N'BackupRestoreDemo_Historical' to N'c:\db\BackupRestoreDemoCopy_Historical.ndf',  
move N'BackupRestoreDemo_log' to N'c:\db\BackupRestoreDemoCopy_log.ldf',  
norecovery,  nounload,  stats = 5;
go

-- Transaction Log restore
restore log [BackupRestoreDemoCopy] 
from disk = N'BackupRestoreDemo.trn' 
with nounload, norecovery, stats = 10,
stopbeforemark = 'lsn:0x<Insert LSN here>';
go

restore database [BackupRestoreDemoCopy] with recovery;
go

select * from BackupRestoreDemoCopy.dbo.Invoices
go

drop database [BackupRestoreDemoCopy]
go