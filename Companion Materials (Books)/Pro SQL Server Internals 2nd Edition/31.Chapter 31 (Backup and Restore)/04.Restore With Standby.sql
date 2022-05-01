/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    Chapter 31.Backup and Restore                         */
/*                         Restore With StandBy                             */
/****************************************************************************/
set noexec off
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

use BackupRestoreDemo
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Invoices') drop table dbo.Invoices;
go

create table dbo.Invoices
(
	InvoiceId int not null
);

insert into dbo.Invoices values(1);
insert into dbo.Invoices values(2);
insert into dbo.Invoices values(3);
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

-- Tran Log Backup 1
backup log BackupRestoreDemo 
to disk = N'BackupRestoreDemo1.trn' 
with format, init,  
name = N'BackupRestoreDemo-Transaction Log Backup', 
stats = 5, checksum
 --, COMPRESSION
go

insert into BackupRestoreDemo.dbo.Invoices values(4);
insert into BackupRestoreDemo.dbo.Invoices values(5);
insert into BackupRestoreDemo.dbo.Invoices values(6);
go

-- Tran Log Backup 2
backup log BackupRestoreDemo 
to disk = N'BackupRestoreDemo2.trn' 
with format, init,  
name = N'BackupRestoreDemo-Transaction Log Backup', 
stats = 5, checksum
 --, COMPRESSION
go


/* Recovery with STANDBY */

-- Restoring FULL Database 
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

-- Transaction Log backup 1 restore with STANDBY
restore log [BackupRestoreDemoCopy] 
from disk = N'BackupRestoreDemo1.trn' 
with stats = 10,
standby = 'c:\db\BackupRestoreDemo_undo.trn';
go

-- You can query the data now
select * from BackupRestoreDemoCopy.dbo.Invoices;
go

-- Completing restore
restore log [BackupRestoreDemoCopy] 
from disk = N'BackupRestoreDemo2.trn' 
with nounload, norecovery, stats = 10;
go

restore database [BackupRestoreDemoCopy] with recovery;
go

/*** Dropping database ***/
drop database [BackupRestoreDemoCopy]; 
go
