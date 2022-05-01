/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*               Chapter 30. Designing a Backup Strategy                    */
/*                    Restoring DB After Disaster                           */
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

/*** Let's assume that disaster happens here. In this example, we will move Operational filegroup to another folder ***/

-- Step 1: Taking Tail-Log backup
backup log BackupRestoreDemo 
to disk = N'BackupRestoreDemo-Tail.trn' 
with no_truncate, format, init,  
name = N'BackupRestoreDemo-Tail-Log Backup', 
stats = 5, checksum
 --, COMPRESSION
go

/*** Dropping database here to demonstrate recovery from scratch ***/
drop database BackupRestoreDemo
go

-- Step 2: Restoring FULL backup
-- Change path of the data/log files
restore database [BackupRestoreDemo] 
from disk = N'BackupRestoreDemo.bak' 
with file = 1,  
move N'BackupRestoreDemo_Operational' to N'c:\db1\BackupRestoreDemo_Operational.ndf',  
norecovery,  nounload,  stats = 5;

-- Step 3: Transaction Log backup
restore log [BackupRestoreDemo] 
from disk = N'BackupRestoreDemo.trn' 
with nounload, norecovery, stats = 10;

-- Step 4:Tail-Log backup
restore log [BackupRestoreDemo] 
from disk = N'BackupRestoreDemo-Tail.trn' 
with nounload, norecovery, stats = 10;

restore database [BackupRestoreDemo] with recovery;
go

