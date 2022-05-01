/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. In-Memory OLTP Concurrency Model               */
/*                      Database Creation Script                            */
/****************************************************************************/
set noexec off
go

use master
go

declare
	@EngineEdition int = convert(int, serverproperty('EngineEdition')) -- 3 means Enterprise
	,@EngineVersion int = convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) 

if 
	not
	(
		(
			(@EngineEdition = 3) and -- Enterprise / Developer
			(@EngineVersion >= 12) -- SQL Server 2014
		)
		or 
		(
			(@EngineVersion > 13) -- SQL Server 2017+
		)
		or
		(
			(@EngineVersion = 13) -- SQL Server 2016
			and 
			left(convert(varchar(64),serverproperty('productlevel')),2) = 'SP'
		) -- SQL Server 2016 with SP	
	)
begin
	raiserror('SQL Server version does not support In-Memory OLTP',16,1) with nowait
	set noexec on
end
go

if exists
(
	select * from sys.databases where name = 'SQLServerInternalsHK'
)
begin
	raiserror('Database [SQLServerInternalsHK] already created',16,1)
	set noexec on
end
go

declare
	@dataPath nvarchar(512) = convert(nvarchar(512),serverproperty('InstanceDefaultDataPath'))
	,@logPath nvarchar(512) = convert(nvarchar(512),serverproperty('InstanceDefaultLogPath'))

/*** REPLACE IF YOU WANT TO STORE IN-MEMORY OLTP FILES IN THE DIFFERENT PLACE ***/
declare
	@HKPath nvarchar(512) = @dataPath + 'SQLServerInternalsHK_HKData'
	
declare
	@SQL nvarchar(max)

select @SQL = 
N'create database [SQLServerInternalsHK] on 
primary (name=N''SQLServerInternalsHK'', filename=N''' + @dataPath + N'SQLServerInternalsHK.mdf'', size=102400KB, filegrowth = 102400KB),
filegroup [HKData] contains memory_optimized_data (name=N''SQLServerInternalsHK_HekatonData'', filename=N''' + @HKPath + N''')
log on (name=N''SQLServerInternalsHK_log'', filename=N''' + @logPath + N'SQLServerInternalsHK.ldf'', size=256000KB, filegrowth = 256000KB)
--COLLATE Latin1_General_100_CS_AI;

alter database [SQLServerInternalsHK] set recovery simple;'

raiserror('Creating database SQLServerInternalsHK',0,1) with nowait
raiserror('Data Path: %s',0,1,@dataPath) with nowait
raiserror('Log Path: %s',0,1,@logPath) with nowait
raiserror('In-Memory OLTP Folder: %s',0,1,@HKPath) with nowait
raiserror('Statement:',0,1) with nowait
raiserror(@sql,0,1) with nowait

exec sp_executesql @sql
go

