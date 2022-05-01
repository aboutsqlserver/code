/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                Chapter 05: Data Storage and Query Tuning                 */
/*                          Analyzing Statistics                            */
/****************************************************************************/

USE SQLServerInternals
GO

IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'DBObjects') DROP TABLE dbo.DBObjects;
GO

CREATE TABLE dbo.DBObjects
(
	ID INT NOT NULL IDENTITY(1,1),
	Name SYSNAME NOT NULL,
	CreateDate DATETIME NOT NULL
);

CREATE UNIQUE CLUSTERED INDEX IDX_DBObjects_ID ON dbo.DBObjects(ID);
GO

-- Populating table with some data
INSERT INTO dbo.DBObjects(Name,CreateDate)
	SELECT name, create_date FROM sys.objects ORDER BY name;

-- Creating some duplicate values
INSERT INTO dbo.DBObjects(Name, CreateDate)
	SELECT t1.Name, t1.CreateDate
	FROM dbo.DBObjects t1 CROSS JOIN dbo.DBObjects t2
	WHERE t1.ID = 5 AND t2.ID between 1 AND 20;

CREATE NONCLUSTERED INDEX IDX_DBObjects_Name_CreateDate
ON dbo.DBObjects(Name, CreateDate);
GO

-- Analyzing statistics
DBCC SHOW_STATISTICS('dbo.DBObjects','IDX_DBObjects_Name_CreateDate');
GO

-- Looking at histogram (SQL Server 2016+)
SELECT 
	sp.*
FROM 
	sys.tables t WITH (NOLOCK) JOIN sys.indexes i WITH (NOLOCK) ON
		t.object_id = i.object_id
	CROSS APPLY
		sys.dm_db_stats_histogram(t.object_id, i.index_id) sp
WHERE
	t.object_id = OBJECT_ID(N'dbo.DBObjects') AND
	i.name = 'IDX_DBObjects_Name_CreateDate'
OPTION (MAXDOP 1, RECOMPILE);
GO

-- Analyzing Statistics Properties
SELECT
	s.stats_id AS [Stat ID]
	,sc.name + '.' + t.name AS [Table]
	,s.name AS [Statistics]
	,p.last_updated
	,p.rows
	,p.rows_sampled
	,p.modification_counter AS [Mod Count]
FROM
	sys.stats s JOIN sys.tables t ON
		s.object_id = t.object_id
	JOIN sys.schemas sc ON
		t.schema_id = sc.schema_id
	OUTER APPLY
		sys.dm_db_stats_properties(t.object_id,s.stats_id) p
WHERE
	s.object_id = OBJECT_ID(N'dbo.DBObjects')
OPTION (RECOMPILE, MAXDOP 1);
GO