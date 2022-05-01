/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 07: Memory Issues                      */
/*                      Memory-Intensive Query Optimization                 */
/****************************************************************************/

USE SQLServerInternals
GO

IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'Orders') DROP TABLE dbo.Orders;
GO

CREATE TABLE dbo.Orders
(
	OrderID INT NOT NULL,
	OrderDate DATETIME2(0) NOT NULL,
	Placeholder CHAR(8000) NULL,
	CONSTRAINT PK_Orders 
		PRIMARY KEY CLUSTERED(OrderID)
);

;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 ROWS
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 ROWS
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 ROWS
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 ROWS
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 ROWS
,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)
INSERT INTO dbo.Orders(OrderID, OrderDate)
	SELECT ID, DATEADD(day,ID % 365, '2021-01-01')
	FROM IDs;
GO

-- Enable "Display Actual Execution Plan"

-- Test Query. You'd see tempdb split 
SET STATISTICS IO ON

SELECT TOP 200 OrderID, OrderDate, Placeholder
FROM dbo.Orders
ORDER BY OrderDate DESC
OPTION (MAXDOP 1);

SET STATISTICS IO OFF
GO

-- Create the index to avoid Sort
CREATE INDEX IDX_Orders_OrderDate ON dbo.Orders(OrderDate);
GO

-- No Sort as the data is "pre-sorted" by the index
SET STATISTICS IO ON

SELECT TOP 200 OrderID, OrderDate, Placeholder
FROM dbo.Orders
ORDER BY OrderDate DESC
OPTION (MAXDOP 1);

SET STATISTICS IO OFF
GO

-- Cardinality estimation errors

-- Test query
-- All estimations are good
SET STATISTICS IO ON

SELECT TOP 200 OrderID, OrderDate, Placeholder
FROM dbo.Orders
WHERE OrderDate BETWEEN '2021-07-01' AND '2021-08-01'
ORDER BY Placeholder
OPTION (MAXDOP 1, RECOMPILE);

SET STATISTICS IO OFF;
GO

-- Disabling auto-update statistics in the index and deleting data making statistics stake
ALTER INDEX IDX_Orders_OrderDate ON dbo.Orders
SET (STATISTICS_NORECOMPUTE = ON);

DELETE FROM dbo.Orders
WHERE OrderDate BETWEEN '2021-07-02' AND '2021-09-01';
GO

-- Excessive memory grant due to cardinality estimation error
SET STATISTICS IO ON

SELECT TOP 200 OrderID, OrderDate, Placeholder
FROM dbo.Orders
WHERE OrderDate BETWEEN '2021-07-01' AND '2021-08-01'
ORDER BY Placeholder
OPTION (MAXDOP 1, RECOMPILE);

SET STATISTICS IO OFF;
GO

-- Updating statistics
UPDATE STATISTICS dbo.Orders IDX_Orders_OrderDate WITH FULLSCAN;
GO

-- All back to normal
SET STATISTICS IO ON

SELECT TOP 200 OrderID, OrderDate, Placeholder
FROM dbo.Orders
WHERE OrderDate BETWEEN '2021-07-01' AND '2021-08-01'
ORDER BY Placeholder
OPTION (MAXDOP 1, RECOMPILE);

SET STATISTICS IO OFF;
GO


-- Row size estimation
-- Row size of Sort operator is 8,017 bytes due to Placeholder CHAR(8000) column
SET STATISTICS IO ON

SELECT TOP 200 OrderID, OrderDate, Placeholder
FROM dbo.Orders
WHERE OrderDate BETWEEN '2021-07-01' AND '2021-08-01'
ORDER BY Placeholder
OPTION (MAXDOP 1, RECOMPILE);

SET STATISTICS IO OFF;
GO

-- Altering to VARCHAR
ALTER TABLE dbo.Orders ALTER COLUMN Placeholder VARCHAR(32);
GO

-- Now row size of Sort operator is 37 bytes
SET STATISTICS IO ON

SELECT TOP 200 OrderID, OrderDate, Placeholder
FROM dbo.Orders
WHERE OrderDate BETWEEN '2021-07-01' AND '2021-08-01'
ORDER BY Placeholder
OPTION (MAXDOP 1, RECOMPILE);

SET STATISTICS IO OFF;
GO