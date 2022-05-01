/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*               Chapter 30. Designing a Backup Strategy                    */
/*                          Piecemeal Restore                               */
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
		raiserror('You need to create BackupRestoreDemo DB with "01.Create Test DB.sql" script',16,1)
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

/*** Let's assume that disaster happens here and we need to perform piecemeal restore of DB ***/

-- Step 1: Taking Tail-Log backup
backup log BackupRestoreDemo 
to disk = N'BackupRestoreDemo-Tail.trn' 
with no_truncate, format, init,  
name = N'BackupRestoreDemo-Tail-Log Backup', 
stats = 5, checksum
 --, COMPRESSION
go

/*** Dropping database. Just to assume disaster happened ***/
drop database BackupRestoreDemo
go

-- Step 2: Restoring FULL backup without Historical FG
-- Change path of the data/log files
restore database [BackupRestoreDemo] 
filegroup = 'Primary', filegroup = 'Entities', filegroup = 'Operational'
from disk = N'BackupRestoreDemo.bak' 
with file = 1,  
move N'BackupRestoreDemo' to N'c:\db\BackupRestoreDemoDev.mdf',  
move N'BackupRestoreDemo_Entities' to N'c:\db\BackupRestoreDemoDev_Enttities.ndf',  
move N'BackupRestoreDemo_Operational' to N'c:\db\BackupRestoreDemoDev_Operational.ndf',  
-- No Historical Here
move N'BackupRestoreDemo_log' to N'c:\db\BackupRestoreDemoDev_log.ldf',  
norecovery,  nounload,  partial, stats = 5;

-- Step 3: Transaction Log backup
restore log [BackupRestoreDemo] 
from disk = N'BackupRestoreDemo.trn' 
with nounload, norecovery, stats = 10;

-- Step 4: Tail-Log backup
restore log [BackupRestoreDemo] 
from disk = N'BackupRestoreDemo-Tail.trn' 
with nounload, norecovery, stats = 10;

-- Step 5: Recovery
restore database [BackupRestoreDemo] with recovery;
go

-- State of the files
select file_id, name, state_desc, physical_name
from BackupRestoreDemo.sys.database_files
go

/*** Restoring Historical FG ***/
-- Change path of the data/log files
-- Step 1: Restoring FG from full backup
restore database [BackupRestoreDemo] 
filegroup = 'Historical'
from disk = N'BackupRestoreDemo.bak' 
with file = 1,  
move N'BackupRestoreDemo_Historical' to N'c:\db\BackupRestoreDemoDev_Historical.ndf',  
norecovery,  nounload,  stats = 5;

-- Step 2: Transaction Log backup
restore log [BackupRestoreDemo] 
from disk = N'BackupRestoreDemo.trn' 
with nounload, norecovery, stats = 10;

-- Step 3: Tail-Log backup
restore log [BackupRestoreDemo] 
from disk = N'BackupRestoreDemo-Tail.trn' 
with nounload, norecovery, stats = 10;

-- Step 4: Recovery
restore database [BackupRestoreDemo] with recovery;
go

