/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                Chapter 05: Data Storage and Query Tuning                 */
/*                      Filtered Indexes and Statistics                     */
/****************************************************************************/

USE SQLServerInternals
GO

IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'Data') DROP TABLE dbo.Data;
GO

CREATE TABLE dbo.Data
(
	RecId INT NOT NULL,
	Processed BIT NOT NULL,
	/* Other Columns */
);

CREATE UNIQUE CLUSTERED INDEX IDX_DATA_RECID ON dbo.Data(RecId);
GO

;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 ROWS
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 ROWS
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 ROWS
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 ROWS
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 ROWS
,IDS(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)
INSERT INTO dbo.Data(RecId, Processed)
	SELECT ID, 0
	FROM IDS;
go

-- Always add columns from the filter as INCLUDE or KEY columns
CREATE NONCLUSTERED INDEX IDX_Data_Unprocessed_Filtered
ON dbo.Data(RecId)
INCLUDE(Processed)
WHERE Processed = 0;
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
	s.object_id = OBJECT_ID(N'dbo.Data')
OPTION (RECOMPILE, MAXDOP 1);
GO

-- Modifying Key column
UPDATE dbo.Data SET RecId = -RecId WHERE RecId IN (1,3);

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
	s.object_id = OBJECT_ID(N'dbo.Data')
OPTION (RECOMPILE, MAXDOP 1);
GO

-- Updating column from the filter
UPDATE dbo.Data SET Processed = 1;

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
	s.object_id = OBJECT_ID(N'dbo.Data')
OPTION (RECOMPILE, MAXDOP 1);
GO
