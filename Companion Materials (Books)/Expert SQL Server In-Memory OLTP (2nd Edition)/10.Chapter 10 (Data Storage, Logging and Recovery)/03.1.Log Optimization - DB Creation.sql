/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 10: Data Storage, Logging and Recovery              */
/*                  03.Log Optimization (Database Creation)                 */
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
	select * from sys.databases where name = 'InMemoryOLTP2016_Ch10'
)
begin
	raiserror('Database InMemoryOLTP2016_Ch10 already created',16,1)
	set noexec on
end
go



declare
	@dataPath nvarchar(512) = convert(nvarchar(512),serverproperty('InstanceDefaultDataPath'))
	,@logPath nvarchar(512) = convert(nvarchar(512),serverproperty('InstanceDefaultLogPath'))

/*** REPLACE IF YOU WANT TO STORE IN-MEMORY OLTP FILES IN THE DIFFERENT PLACE ***/
declare
	@HKPath nvarchar(512) = @dataPath + 'InMemoryOLTP2016_Ch10_HKData'
	
declare
	@SQL nvarchar(max)

select @SQL = 
N'create database [InMemoryOLTP2016_Ch10] on 
primary (name=N''InMemoryOLTP2016_Ch10'', filename=N''' + @dataPath + N'InMemoryOLTP2016_Ch10.mdf'', size=102400KB, filegrowth = 102400KB),
filegroup [HKData] contains memory_optimized_data (name=N''InMemoryOLTP2016_Ch10_HekatonData'', filename=N''' + @HKPath + N''')
log on (name=N''InMemoryOLTP2016_Ch10_log'', filename=N''' + @logPath + N'InMemoryOLTP2016_Ch10.ldf'', size=256000KB, filegrowth = 256000KB);

alter database [InMemoryOLTP2016_Ch10] set recovery full;'

raiserror('Creating database InMemoryOLTP2016_Ch10',0,1) with nowait
raiserror('Data Path: %s',0,1,@dataPath) with nowait
raiserror('Log Path: %s',0,1,@logPath) with nowait
raiserror('Hekaton Folder: %s',0,1,@HKPath) with nowait
raiserror('Statement:',0,1) with nowait
raiserror(@sql,0,1) with nowait

exec sp_executesql @sql
go

