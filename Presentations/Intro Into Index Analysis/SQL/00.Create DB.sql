/****************************************************************************/
/*                        Intro into Index Analysis                         */
/*																			*/
/*                         Dmitri V. Korotkevitch                           */
/*                        http://aboutsqlserver.com                         */
/*                          dk@aboutsqlserver.com                           */
/****************************************************************************/
/*						      Database Creation                             */
/****************************************************************************/


set noexec off
go

use master
go

if exists
(
	select * from sys.databases where name = 'SQLServerInternals'
)
begin
	raiserror('Database SQLServerInternals already exists',16,1)
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

if @version >= 11 -- SQL Server 2014+
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
N'create database [SQLServerInternals]
on primary (name=N''SQLServerInternals'', filename=N''%DATA%SqlServerInternals.mdf'', size=10MB, filegrowth = 10MB),
filegroup [FASTSTORAGE] (name=N''SqlServerInternals_FAST'', filename=N''%DATA%SqlServerInternals_FAST.ndf'', size=100MB, filegrowth = 100MB), 
filegroup [FG2014] (name=N''SqlServerInternals_2014'', filename=N''%DATA%SqlServerInternals_2014.ndf'', size=100MB, filegrowth = 100MB),
filegroup [FG2015] (name=N''SqlServerInternals_2015'', filename=N''%DATA%SqlServerInternals_2015.ndf'', size=100MB, filegrowth = 100MB),
filegroup [FG2016] (name=N''SqlServerInternals_2016'', filename=N''%DATA%SqlServerInternals_2016.ndf'', size=100MB, filegrowth = 100MB)
log on (name=N''SQLServerInternals_log'', filename=N''%LOG%SqlServerInternals.ldf'', size=256MB, filegrowth = 256MB);

alter database [SQLServerInternals] set recovery simple;
alter database [SQLServerInternals] modify filegroup [FASTSTORAGE] default;

'
			,'%DATA%',@dataPath
		),'%LOG%',@logPath
	)

raiserror('Creating database SQLServerInternals',0,1) with nowait
raiserror('Data Path: %s',0,1,@dataPath) with nowait
raiserror('Log Path: %s',0,1,@logPath) with nowait
raiserror('Statement:',0,1) with nowait
raiserror(@sql,0,1) with nowait

exec sp_executesql @sql
go

/*
exec sys.sp_configure N'optimize for ad hoc workloads', 0
go
reconfigure with override
go
*/