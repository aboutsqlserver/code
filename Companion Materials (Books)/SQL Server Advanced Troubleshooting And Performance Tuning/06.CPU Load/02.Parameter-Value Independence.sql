/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 06: CPU Load                           */
/*                      Parameter-SValue Independence                       */
/****************************************************************************/

USE SQLServerInternals
GO

IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'Orders') DROP TABLE dbo.Orders;
IF EXISTS(SELECT * FROM sys.procedures p JOIN sys.schemas s ON p.schema_id = s.schema_id WHERE s.name = 'dbo' AND p.name = 'GetTotalPerStore') DROP PROC dbo.GetTotalPerStore;
IF EXISTS(SELECT * FROM sys.procedures p JOIN sys.schemas s ON p.schema_id = s.schema_id WHERE s.name = 'dbo' AND p.name = 'SearchOrders') DROP PROC dbo.SearchOrders;
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

-- This is extremely bad pattern to use
CREATE PROC dbo.SearchOrders
(
	@StoreId INT = NULL
	,@CustomerId UNIQUEIDENTIFIER = NULL
)
AS
	SELECT OrderId, CustomerId, Amount, Fulfilled
	FROM dbo.Orders
	WHERE
		((@StoreId IS NULL) OR (StoreId = @StoreId)) AND
		((@CustomerId IS NULL) OR (CustomerId = @CustomerId))
	OPTION (MAXDOP 1);
GO

-- Enable "Display Actual Execution Plan"
-- Index Scan instead of Index Seek
SET STATISTICS IO ON
EXEC dbo.SearchOrders
	@StoreId = 99
	,@CustomerId = 'A65C047D-5B08-4041-B2FE-8E3DD6570B8A';
SET STATISTICS IO OFF
GO

-- Mitigations
-- 1. OPTION (RECOMPILE) - Will add to CPU load. Not a best option with frequently executed queries
ALTER PROC dbo.SearchOrders
(
	@StoreId INT = NULL
	,@CustomerId UNIQUEIDENTIFIER = NULL
)
AS
	SELECT OrderId, CustomerId, Amount, Fulfilled
	FROM dbo.Orders
	WHERE
		((@StoreId IS NULL) OR (StoreId = @StoreId)) AND
		((@CustomerId IS NULL) OR (CustomerId = @CustomerId))
	OPTION (MAXDOP 1, RECOMPILE);
GO

SET STATISTICS IO ON
EXEC dbo.SearchOrders
	@StoreId = 99
	,@CustomerId = 'A65C047D-5B08-4041-B2FE-8E3DD6570B8A';
SET STATISTICS IO OFF
GO

-- 2. IF logic. Hard to maintain with large number of parameters
-- You don't need to specify all combination of parameters thouth
ALTER PROC dbo.SearchOrders
(
	@StoreId INT = NULL
	,@CustomerId UNIQUEIDENTIFIER = NULL
)
AS
	IF @StoreId IS NULL AND @CustomerId IS NULL
		SELECT OrderId, CustomerId, Amount, Fulfilled
		FROM dbo.Orders
		OPTION (MAXDOP 1, RECOMPILE);
	ELSE IF @StoreId IS NULL AND @CustomerId IS NOT NULL
		SELECT OrderId, CustomerId, Amount, Fulfilled
		FROM dbo.Orders
		WHERE CustomerId = @CustomerId
		OPTION (MAXDOP 1, RECOMPILE);
	ELSE IF @StoreId IS NOT NULL AND @CustomerId IS  NULL
		SELECT OrderId, CustomerId, Amount, Fulfilled
		FROM dbo.Orders
		WHERE StoreId = @StoreId
		OPTION (MAXDOP 1, RECOMPILE);
	ELSE 
		SELECT OrderId, CustomerId, Amount, Fulfilled
		FROM dbo.Orders
		WHERE
			StoreId = @StoreId AND
			CustomerId = @CustomerId
		OPTION (MAXDOP 1, RECOMPILE);
GO

SET STATISTICS IO ON
EXEC dbo.SearchOrders
	@StoreId = 99
	,@CustomerId = 'A65C047D-5B08-4041-B2FE-8E3DD6570B8A';
SET STATISTICS IO OFF
GO

-- 3. Dynamic SQL. Be careful with SQL Injection
ALTER PROC dbo.SearchOrders
(
	@StoreId INT = NULL
	,@CustomerId UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
DECLARE
	@SQL nvarchar(max) =
N'SELECT OrderId, CustomerId, Amount, Fulfilled
FROM dbo.Orders
WHERE
(1=1) ' +
	IIF(@StoreId IS NOT NULL, N'AND (StoreId = @StoreId)','') +
	IIF(@CustomerId IS NOT NULL, N'AND (CustomerId = @CustomerId)','');

	EXEC sp_executesql
		@SQL = @SQL
		,@Params = N'@StoreId INT, @CustomerId UNIQUEIDENTIFIER'
		,@StoreId = @StoreId, @CustomerId = @CustomerId;
END
GO

SET STATISTICS IO ON
EXEC dbo.SearchOrders
	@StoreId = 99
	,@CustomerId = 'A65C047D-5B08-4041-B2FE-8E3DD6570B8A';
SET STATISTICS IO OFF
GO

-- Issues with filtered indexes. May also happen during auto-parameterization
CREATE NONCLUSTERED INDEX IDX_Orders_ActiveOrders_Filtered
ON dbo.Orders(OrderId)
INCLUDE(Fulfilled)
WHERE Fulfilled = 0;
GO

DECLARE
	@Fulfilled BIT = 0;

SELECT COUNT(*) AS [Active Order Count]
FROM dbo.Orders
WHERE Fulfilled = @Fulfilled;