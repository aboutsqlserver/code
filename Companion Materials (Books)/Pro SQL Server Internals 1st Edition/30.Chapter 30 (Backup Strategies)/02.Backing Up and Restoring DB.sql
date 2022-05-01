/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*               Chapter 30. Designing a Backup Strategy                    */
/*                    Backing Up and Restoring DB                           */
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

/*** Backing Up Database ***/

-- Full backup
backup database BackupRestoreDemo 
to disk = N'BackupRestoreDemo.bak' 
with format, init,  
name = N'BackupRestoreDemo-Full Database Backup', 
stats = 5, checksum
 --, COMPRESSION
go

-- Differential Backup
backup database BackupRestoreDemo 
to disk = N'BackupRestoreDemo.bak' 
with differential, noformat, noinit,  
name = N'BackupRestoreDemo-Differential Database Backup', 
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

/*** Restoring Database ***/

-- Initial FULL backup
-- Change path of the data/log files
restore database [BackupRestoreDemoDev] 
from disk = N'BackupRestoreDemo.bak' 
with file = 1,  
move N'BackupRestoreDemo' to N'c:\db\BackupRestoreDemoDev.mdf',  
move N'BackupRestoreDemo_Entities' to N'c:\db\BackupRestoreDemoDev_Enttities.ndf',  
move N'BackupRestoreDemo_Operational' to N'c:\db\BackupRestoreDemoDev_Operational.ndf',  
move N'BackupRestoreDemo_Historical' to N'c:\db\BackupRestoreDemoDev_Historical.ndf',  
move N'BackupRestoreDemo_log' to N'c:\db\BackupRestoreDemoDev_log.ldf',  
norecovery,  nounload,  stats = 5;

-- Differential backup
restore database [BackupRestoreDemoDev] 
from disk = N'BackupRestoreDemo.bak' 
with file = 2,  
norecovery,  nounload,  stats = 5;

-- Transaction Log backup
restore log [BackupRestoreDemoDev] 
from disk = N'BackupRestoreDemo.trn' 
with nounload, norecovery, stats = 10;

restore database [BackupRestoreDemoDev] with recovery;
go

/*** Dropping database ***/
drop database [BackupRestoreDemoDev]
go

