/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Database Creation Script                            */
/****************************************************************************/
set noexec off
go

use master
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 13 
begin
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait
	set noexec on
end
go

if exists
(
	select * from sys.databases where name = 'InMemoryOLTP2016'
)
begin
	raiserror('Database [InMemoryOLTP2016] already created',16,1)
	set noexec on
end
go

declare
	@dataPath nvarchar(512) = convert(nvarchar(512),serverproperty('InstanceDefaultDataPath'))
	,@logPath nvarchar(512) = convert(nvarchar(512),serverproperty('InstanceDefaultLogPath'))

/*** REPLACE IF YOU WANT TO STORE IN-MEMORY OLTP FILES IN THE DIFFERENT PLACE ***/
declare
	@HKPath nvarchar(512) = @dataPath + 'InMemoryOLTP2016_HKData'
	
declare
	@SQL nvarchar(max)

select @SQL = 
N'create database [InMemoryOLTP2016] on 
primary (name=N''InMemoryOLTP2016'', filename=N''' + @dataPath + N'InMemoryOLTP2016.mdf'', size=102400KB, filegrowth = 102400KB),
filegroup [HKData] contains memory_optimized_data (name=N''InMemoryOLTP2016_HekatonData'', filename=N''' + @HKPath + N'''),
filegroup LOGDATA 
(name = N''LogData1'', filename=N''' + @dataPath + N'InMemoryOLTP2016LogData1.ndf''),
(name = N''LogData2'', filename=N''' + @dataPath + N'InMemoryOLTP2016LogData2.ndf''),
(name = N''LogData3'', filename=N''' + @dataPath + N'InMemoryOLTP2016LogData3.ndf''),
(name = N''LogData4'', filename=N''' + @dataPath + N'InMemoryOLTP2016LogData4.ndf''),
filegroup FG2017 
(name = N''FG2017'', filename=N''' + @dataPath + N'InMemoryOLTP2016FG2017.ndf''),
filegroup FG2016 
(name = N''FG2016'', filename=N''' + @dataPath + N'InMemoryOLTP2016FG2016.ndf'')
log on (name=N''InMemoryOLTP2016_log'', filename=N''' + @logPath + N'InMemoryOLTP2016.ldf'', size=256000KB, filegrowth = 256000KB);

alter database [InMemoryOLTP2016] set recovery simple;'

raiserror('Creating database InMemoryOLTP2016',0,1) with nowait
raiserror('Data Path: %s',0,1,@dataPath) with nowait
raiserror('Log Path: %s',0,1,@logPath) with nowait
raiserror('In-Memory OLTP Folder: %s',0,1,@HKPath) with nowait
raiserror('Statement:',0,1) with nowait
raiserror(@sql,0,1) with nowait

exec sp_executesql @sql
go

