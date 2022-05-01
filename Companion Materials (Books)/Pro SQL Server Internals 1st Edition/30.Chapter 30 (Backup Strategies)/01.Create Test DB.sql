/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*               Chapter 30. Designing a Backup Strategy                    */
/*                       Creating Test Database                             */
/****************************************************************************/
set noexec off
go

use master
go

if exists
(
	select * from sys.databases where name = 'BackupRestoreDemo'
)
begin
	raiserror('Database BackupRestoreDemo already created',16,1)
	set noexec on
end
go


declare
	@version int
	,@dataPath nvarchar(512)
	,@logPath nvarchar(512) 

set @version = 
	convert(int,
		left(
			convert(nvarchar(128), serverproperty('ProductVersion')),
			charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
		)
	)

if @version >= 11 -- SQL Server 2012+
begin
	select 
		@dataPath = convert(nvarchar(512),serverproperty('InstanceDefaultDataPath'))
		,@logPath = convert(nvarchar(512),serverproperty('InstanceDefaultLogPath'))
end
else begin
	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @dataPath output
	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @logPath output
end

-- Creating database in the same folder with master
if @dataPath is null
	select @dataPath = substring(physical_name, 1, len(physical_name) - charindex('\', reverse(physical_name))) + '\'
	from master.sys.database_files 
	where file_id = 1

if @logPath is null
	select @logPath = substring(physical_name, 1, len(physical_name) - charindex('\', reverse(physical_name))) + '\'
	from master.sys.database_files 
	where file_id = 2
	
if @dataPath is null or @logPath is null
begin
	raiserror('Cannot obtain path for data and/or log file',16,1)
	set noexec on
end

if right(@dataPath, 1) <> '\'
	select @dataPath = @dataPath + '\'
if right(@logPath, 1) <> '\'
	select @logPath = @logPath + '\'
	
declare
	@SQL nvarchar(max)

select @SQL = 
	replace
	(
		replace(
N'create database [BackupRestoreDemo]
on primary (name=N''BackupRestoreDemo'', filename=N''%DATA%BackupRestoreDemo.mdf'', size=102400KB, filegrowth = 102400KB),
filegroup [Entities] (name=N''BackupRestoreDemo_Entities'', filename=N''%DATA%BackupRestoreDemo_Entities.ndf'', size=102400KB, filegrowth = 102400KB), 
filegroup [Operational] (name=N''BackupRestoreDemo_Operational'', filename=N''%DATA%BackupRestoreDemo_Operational.ndf'', size=102400KB, filegrowth = 102400KB),
filegroup [Historical] (name=N''BackupRestoreDemo_Historical'', filename=N''%DATA%BackupRestoreDemo_Historical.ndf'', size=102400KB, filegrowth = 102400KB)
log on (name=N''BackupRestoreDemo_log'', filename=N''%LOG%BackupRestoreDemo.ldf'', size=20000KB, filegrowth = 20000KB);

alter database [BackupRestoreDemo] set recovery full
'
			,'%DATA%',@dataPath
		),'%LOG%',@logPath
	)

raiserror('Creating database BackupRestoreDemo',0,1) with nowait
raiserror('Data Path: %s',0,1,@dataPath) with nowait
raiserror('Log Path: %s',0,1,@logPath) with nowait
raiserror('Statement:',0,1) with nowait
raiserror(@sql,0,1) with nowait

exec sp_executesql @sql
go


