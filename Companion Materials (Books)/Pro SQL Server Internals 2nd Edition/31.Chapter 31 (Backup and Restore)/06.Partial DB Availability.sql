/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    Chapter 31.Backup and Restore                         */
/*                        Partial DB Availability                           */
/****************************************************************************/
set noexec off
go

use master
go

if not exists 
( 
	select	*
	from	sys.databases
	where	name = 'BackupRestoreDemo' ) 
	begin
		raiserror('Please create BackupRestoreDemo DB with "01.Create Test DB.sql" script',16,1);
		set noexec on
	end
go

/*** Initial Stage: Backing Up Database ***/

-- Full backup
backup database BackupRestoreDemo 
to disk = N'BackupRestoreDemo.bak' 
with format, init,  
name = N'BackupRestoreDemo-Full Database Backup', 
stats = 5, checksum
 --, COMPRESSION
go

-- Tran Log Backup
backup log BackupRestoreDemo 
to disk = N'BackupRestoreDemo.trn' 
with format, init,  
name = N'BackupRestoreDemo-Transaction Log Backup', 
stats = 5, checksum
 --, COMPRESSION
go

/*** Let's assume that disaster happens here and we need to recover Historical DB restoring it into different drive ***/

-- Step 1: Marking file as OFFLINE. This work in any edition of SQL Server, however only 
-- Enterprise Edition supports partial availability

alter database BackupRestoreDemo
modify file(name = BackupRestoreDemo_Historical, offline);
go

-- State of the files
select file_id, name, state_desc, physical_name
from BackupRestoreDemo.sys.database_files;
go

-- Step 2: Taking Tail-Log backup
backup log BackupRestoreDemo 
to disk = N'BackupRestoreDemo-Tail.trn' 
with no_truncate, format, init,  
name = N'BackupRestoreDemo-Tail-Log Backup', 
stats = 5, checksum
 --, COMPRESSION
go


-- Step 3: Restoring FULL backup
-- Change path of the data/log files
restore database [BackupRestoreDemo] 
file = N'BackupRestoreDemo_Historical'
from disk = N'BackupRestoreDemo.bak' 
with file = 1,  
move N'BackupRestoreDemo_Historical' to N'c:\db1\BackupRestoreDemo_Historical.ndf',  
norecovery,  nounload,  stats = 5;

-- State of the files
select file_id, name, state_desc, physical_name
from BackupRestoreDemo.sys.database_files;
go

-- Step 4: Transaction Log backup
restore log [BackupRestoreDemo] 
from disk = N'BackupRestoreDemo.trn' 
with nounload, norecovery, stats = 10;

-- Step 5: Tail-Log backup
restore log [BackupRestoreDemo] 
from disk = N'BackupRestoreDemo-Tail.trn' 
with nounload, norecovery, stats = 10;

restore database [BackupRestoreDemo] with recovery;
go

-- State of the files
select file_id, name, state_desc, physical_name
from BackupRestoreDemo.sys.database_files;
go