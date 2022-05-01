/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                Chapter 05: Data Storage and Query Tuning                 */
/*                                  JOINs                                   */
/****************************************************************************/

USE SQLServerInternals
GO

IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'T1') DROP TABLE dbo.T1;
IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'T2') DROP TABLE dbo.T2;
GO

CREATE TABLE dbo.T1
(
	IndexedCol INT PRIMARY KEY,
	NonIndexedCol INT,
);

CREATE TABLE dbo.T2
(
	IndexedCol INT PRIMARY KEY,
	NonIndexedCol INT,
);

;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 ROWS
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 ROWS
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 ROWS
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 ROWS
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 ROWS
,N6(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N5 AS T2) -- 1,048,576 ROWS
,IDS(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N6)
INSERT INTO dbo.T1(IndexedCol, NonIndexedCol)
	SELECT ID, ID FROM IDS;

INSERT INTO dbo.T2(IndexedCol, NonIndexedCol)
	SELECT IndexedCol, NonIndexedCol FROM dbo.T1;

SET STATISTICS TIME, IO ON

-- LOOP: Indexed vs. Nonindexed
-- Relatively fast: Index Seek ON T2
SELECT COUNT(*)
FROM dbo.T1 INNER LOOP JOIN dbo.T2 ON 
	T1.IndexedCol = T2.IndexedCol
WHERE 
	T1.IndexedCol <= 50000
OPTION (MAXDOP 1);

-- Very slow: Multiple  scans
SELECT COUNT(*)
FROM dbo.T1 INNER LOOP JOIN dbo.T2 ON 
	T1.IndexedCol = T2.NonIndexedCol
WHERE 
	T1.IndexedCol <= 5000
OPTION (MAXDOP 1);


-- LOOP vs HASH
-- Relatively fast: Index Seek ON T2
SELECT COUNT(*)
FROM dbo.T1 INNER LOOP JOIN dbo.T2 ON 
	T1.IndexedCol = T2.IndexedCol
OPTION (MAXDOP 1);

-- Fast: Single Table Scan ON T2
SELECT COUNT(*)
FROM dbo.T1 INNER HASH JOIN dbo.T2 ON 
	T1.IndexedCol = T2.IndexedCol
OPTION (MAXDOP 1);

-- Fast: Single Table Scan ON T2
SELECT COUNT(*)
FROM dbo.T1 INNER HASH JOIN dbo.T2 ON 
	T1.IndexedCol = T2.NonIndexedCol
OPTION (MAXDOP 1);
GO

-- MERGE
-- Fast: Both inputs were sorter
SELECT COUNT(*)
FROM dbo.T1 INNER MERGE JOIN dbo.T2 ON 
	T1.IndexedCol = T2.IndexedCol
OPTION (MAXDOP 1);

-- Sort operator in the plan
SELECT COUNT(*)
FROM dbo.T1 INNER MERGE JOIN dbo.T2 ON 
	T1.IndexedCol = T2.NonIndexedCol
OPTION (MAXDOP 1);
GO

-- SQL Server optimization approach
DECLARE 
	@N INT = 10;

SELECT TOP (@N) T1.IndexedCol, T2.IndexedCol
FROM dbo.T1 JOIN dbo.T2 ON 
	T1.IndexedCol = T2.IndexedCol
OPTION (MAXDOP 1, LOOP JOIN, HASH JOIN, OPTIMIZE FOR (@N = 10));

SELECT TOP (@N) * 
FROM dbo.T1 JOIN dbo.T2 ON 
	T1.IndexedCol = T2.IndexedCol
OPTION (MAXDOP 1, LOOP JOIN, HASH JOIN, OPTIMIZE FOR (@N = 100000));
GO

-- Typical "issue". Check cardinality estimations 
UPDATE dbo.T2 SET NonIndexedCol = 2 WHERE IndexedCol >= 2;
CREATE INDEX IDX_T2_NonIndexedCol ON dbo.T2(NonIndexedCol);
UPDATE dbo.T1 SET NonIndexedCol = 2 WHERE IndexedCol >= 2;
CREATE INDEX IDX_T1_NonIndexedCol ON dbo.T1(NonIndexedCol);
GO

DBCC SHOW_STATISTICS('dbo.T2',IDX_T2_NonIndexedCol);
GO

DECLARE 
	@V INT = 2;

SELECT COUNT(*)
FROM dbo.T1 JOIN dbo.T2 ON 
	T1.NonIndexedCol = T2.NonIndexedCol
WHERE 
	T1.IndexedCol between 101 and 125 and
	T1.NonIndexedCol = @V
OPTION (MAXDOP 1, LOOP JOIN, HASH JOIN, OPTIMIZE FOR (@V = 1));
GO

