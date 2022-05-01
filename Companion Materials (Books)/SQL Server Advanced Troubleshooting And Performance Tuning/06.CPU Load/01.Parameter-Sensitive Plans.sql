/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 06: CPU Load                           */
/*             Parameter-Sensitive Plans and Parameter Sniffing             */
/****************************************************************************/

USE SQLServerInternals
GO

/*****************************************************************************
Run this demo in a database with a compatibility level of 150 (SQL Server 2019) 
or below. The code may behave differently in SQLServer 2022 and above.

This demo clears the plan cache. Do not run it on production server!
******************************************************************************/

IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'Orders') DROP TABLE dbo.Orders;
IF EXISTS(SELECT * FROM sys.procedures p JOIN sys.schemas s ON p.schema_id = s.schema_id WHERE s.name = 'dbo' AND p.name = 'GetTotalPerStore') DROP PROC dbo.GetTotalPerStore;
GO


CREATE TABLE dbo.Orders
(
	OrderId INT NOT NULL IDENTITY(1,1),
	OrderNum VARCHAR(32) NOT NULL,
	CustomerId UNIQUEIDENTIFIER NOT NULL,
	Amount MONEY NOT NULL,
	StoreId INT NOT NULL,
	Fulfilled BIT NOT NULL
);

;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2 CROSS JOIN N2 AS T3)
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2 ) -- 1,048,576 rows
,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)
INSERT INTO dbo.Orders(OrderNum, CustomerId, Amount, StoreId, Fulfilled)
	SELECT
		'Order: ' + CONVERT(VARCHAR(32),ID)
		,NEWID()
		,ID % 100
		,ID % 10
		,1
	FROM IDs;

INSERT INTO dbo.Orders(OrderNum, CustomerId, Amount, StoreId, Fulfilled)
	SELECT TOP 10 OrderNum, CustomerId, Amount, 99, 0
	FROM dbo.Orders
	ORDER BY OrderId;

CREATE UNIQUE CLUSTERED INDEX IDX_Orders_OrderId
ON dbo.Orders(OrderId);

CREATE NONCLUSTERED INDEX IDX_Orders_CustomerId
ON dbo.Orders(CustomerId);

CREATE NONCLUSTERED INDEX IDX_Orders_StoreId
ON dbo.Orders(StoreId);
GO

CREATE PROC dbo.GetTotalPerStore(@StoreId int)
AS
	SELECT SUM(Amount) as [Total Amount]
	FROM dbo.Orders
	WHERE StoreId = @StoreId
	OPTION (MAXDOP 1);
GO

-- Enable "Display Actual Execution Plan"
SET STATISTICS IO ON
EXEC dbo.GetTotalPerStore @StoreId = 5;
EXEC dbo.GetTotalPerStore @StoreId = 99;
SET STATISTICS IO OFF
GO

-- Clearing the plan cache (do not run in production!)
-- Emulating parameter sniffing issue
DBCC FREEPROCCACHE;

SET STATISTICS IO ON
EXEC dbo.GetTotalPerStore @StoreId = 99;
EXEC dbo.GetTotalPerStore @StoreId = 5;
SET STATISTICS IO OFF
GO

-- Mitigations
-- 1. OPTION (RECOMPILE) - Will add to CPU load. Not a best option with frequently executed queries
ALTER PROC dbo.GetTotalPerStore(@StoreId int)
AS
	SELECT SUM(Amount) as [Total Amount]
	FROM dbo.Orders
	WHERE StoreId = @StoreId
	OPTION (MAXDOP 1, RECOMPILE);
GO

SET STATISTICS IO ON
EXEC dbo.GetTotalPerStore @StoreId = 99;
EXEC dbo.GetTotalPerStore @StoreId = 5;
SET STATISTICS IO OFF
GO

-- 2. OPTION (OPTIMIZE FOR). Be careful if data distribution changes
ALTER PROC dbo.GetTotalPerStore(@StoreId int)
AS
	SELECT SUM(Amount) as [Total Amount]
	FROM dbo.Orders
	WHERE StoreId = @StoreId
	OPTION (MAXDOP 1, OPTIMIZE FOR (@StoreId = 1));
GO

SET STATISTICS IO ON
EXEC dbo.GetTotalPerStore @StoreId = 99;
EXEC dbo.GetTotalPerStore @StoreId = 5;
SET STATISTICS IO OFF
GO


-- 3. OPTION (OPTIMIZE FOR UNKNOWN). Optimize for most statistically common data
ALTER PROC dbo.GetTotalPerStore(@StoreId int)
AS
	SELECT SUM(Amount) as [Total Amount]
	FROM dbo.Orders
	WHERE StoreId = @StoreId
	OPTION (MAXDOP 1, OPTIMIZE FOR UNKNOWN);
GO

SET STATISTICS IO ON
EXEC dbo.GetTotalPerStore @StoreId = 99;
EXEC dbo.GetTotalPerStore @StoreId = 5;
SET STATISTICS IO OFF
GO