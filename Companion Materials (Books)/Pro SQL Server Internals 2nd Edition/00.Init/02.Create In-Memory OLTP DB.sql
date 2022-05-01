/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   In-Memory OLTP Database Creation                       */
/****************************************************************************/

set noexec off
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 12 
begin
	raiserror('You should have SQL Server 2014/2016 to execute this script',16,1) with nowait
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3 or charindex('X64',@@Version) = 0
begin
	raiserror('That script requires 64-Bit Enterprise or Developer Editions',16,1)
	set noexec on
end
go

use master
go

if exists
(
	select * from sys.databases where name = 'SQLServerInternalsHK'
)
begin
	raiserror('Database SQLServerInternalsHK already exists',16,1)
	set noexec on
end
go


declare
	@dataPath nvarchar(512) = convert(nvarchar(512),serverproperty('InstanceDefaultDataPath'))
	,@logPath nvarchar(512) = convert(nvarchar(512),serverproperty('InstanceDefaultLogPath'))

/*** REPLACE IF YOU WANT TO STORE IN-MEMORY OLTP FILES IN DIFFERENT PLACE ***/
declare
	@HKPath nvarchar(512) = @dataPath + 'SqlServerInternalsHK_HKData'
	
declare
	@SQL nvarchar(max)

select @SQL = 
N'create database [SQLServerInternalsHK] on 
primary (name=N''SQLServerInternalsHK'', filename=N''' + @dataPath + N'SqlServerInternalsHk.mdf'', size=100MB, filegrowth = 50MB),
filegroup [HKData] contains memory_optimized_data (name=N''SqlServerInternalsHk_HekatonData'', filename=N''' + @HKPath + N''')
log on (name=N''SQLServerInternalsHK_log'', filename=N''' + @logPath + N'SqlServerInternalsHk.ldf'', size=100MB, filegrowth = 100MB);

alter database [SqlServerInternalsHk] set recovery simple;'

raiserror('Creating database SQLServerInternalsHk',0,1) with nowait
raiserror('Data Path: %s',0,1,@dataPath) with nowait
raiserror('Log Path: %s',0,1,@logPath) with nowait
raiserror('Hekaton Folder: %s',0,1,@HKPath) with nowait
raiserror('Statement:',0,1) with nowait
raiserror(@sql,0,1) with nowait

exec sp_executesql @sql
go

