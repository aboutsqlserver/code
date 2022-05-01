/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Database Creation Script                           */
/****************************************************************************/

SET NOEXEC OFF
GO

USE master
GO

IF EXISTS
(
	SELECT * FROM sys.databases WHERE name = 'SQLServerInternals'
)
BEGIN
	RAISERROR('Database SQLServerInternals already exists',16,1);
	SET NOEXEC ON
END
GO


DECLARE
	@version INT
	,@dataPath NVARCHAR(512)
	,@logPath NVARCHAR(512) 

SET @version = 
	CONVERT(INT,
		LEFT(
			CONVERT(NVARCHAR(128), SERVERPROPERTY('ProductVersion')),
			CHARINDEX('.',CONVERT(NVARCHAR(128), SERVERPROPERTY('ProductVersion'))) - 1
		)
	);

IF @version >= 11 -- SQL Server 2014+
BEGIN
	SELECT 
		@dataPath = CONVERT(NVARCHAR(512),SERVERPROPERTY('InstanceDefaultDataPath'))
		,@logPath = CONVERT(NVARCHAR(512),SERVERPROPERTY('InstanceDefaultLogPath'));
END
ELSE BEGIN
	EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @dataPath OUTPUT;
	EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @logPath OUTPUT;
END

-- Creating database in the same folder with master
IF @dataPath is null
	SELECT @dataPath = SUBSTRING(physical_name, 1, LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name))) + '\'
	FROM master.sys.database_files 
	WHERE file_id = 1;

IF @logPath is null
	SELECT @logPath = SUBSTRING(physical_name, 1, LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name))) + '\'
	FROM master.sys.database_files 
	WHERE file_id = 2;
	
IF @dataPath IS NULL OR @logPath IS NULL
BEGIN
	RAISERROR('Cannot obtain path for data and/or log file',16,1);
	SET NOEXEC ON
END

IF RIGHT(@dataPath, 1) <> '\'
	SELECT @dataPath = @dataPath + '\';
IF RIGHT(@logPath, 1) <> '\'
	SELECT @logPath = @logPath + '\';
	
DECLARE
	@sql NVARCHAR(MAX)

SELECT @sql = 
	REPLACE
	(
		REPLACE(
N'CREATE DATABASE [SQLServerInternals]
ON PRIMARY (NAME=N''SQLServerInternals'', FILENAME=N''%DATA%SqlServerInternals.mdf'', SIZE=10MB, FILEGROWTH = 10MB),
FILEGROUP [FASTSTORAGE] (NAME=N''SqlServerInternals_FAST'', FILENAME=N''%DATA%SqlServerInternals_FAST.ndf'', SIZE=100MB, FILEGROWTH = 100MB), 
FILEGROUP [FG2014] (NAME=N''SqlServerInternals_2014'', FILENAME=N''%DATA%SqlServerInternals_2014.ndf'', SIZE=100MB, FILEGROWTH = 100MB),
FILEGROUP [FG2015] (NAME=N''SqlServerInternals_2015'', FILENAME=N''%DATA%SqlServerInternals_2015.ndf'', SIZE=100MB, FILEGROWTH = 100MB),
FILEGROUP [FG2016] (NAME=N''SqlServerInternals_2016'', FILENAME=N''%DATA%SqlServerInternals_2016.ndf'', SIZE=100MB, FILEGROWTH = 100MB)
LOG ON (name=N''SQLServerInternals_log'', FILENAME=N''%LOG%SqlServerInternals.ldf'', SIZE=256MB, FILEGROWTH = 256MB)
--COLLATE Latin1_General_100_CS_AI
;

ALTER DATABASE [SQLServerInternals] SET RECOVERY SIMPLE;
ALTER DATABASE [SQLServerInternals] MODIFY FILEGROUP [FASTSTORAGE] DEFAULT;

'
			,'%DATA%',@dataPath
		),'%LOG%',@logPath
	);

RAISERROR('Creating database SQLServerInternals',0,1) WITH NOWAIT;
RAISERROR('Data Path: %s',0,1,@dataPath) WITH NOWAIT;
RAISERROR('Log Path: %s',0,1,@logPath) WITH NOWAIT;
RAISERROR('Statement:',0,1) WITH NOWAIT;
RAISERROR(@sql,0,1) WITH NOWAIT;

EXEC sp_executesql @sql;
GO

