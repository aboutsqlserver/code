/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 06: CPU Load                           */
/*                Plan Guides: FORCED and SIMPLE parameterization           */
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

CREATE NONCLUSTERED INDEX IDX_Orders_ActiveOrders_Filtered
ON dbo.Orders(OrderId)
INCLUDE(Fulfilled)
WHERE Fulfilled = 0;
GO

-- Setting SIMPLE parameterization
ALTER DATABASE [SQLServerInternals] SET PARAMETERIZATION SIMPLE;
GO

-- Enable "Display Actual Execution Plan"

-- The following statement is not auto-parameterized
SELECT TOP 1 OrderId FROM dbo.Orders WHERE CustomerId = 'B970D68B-F88E-438B-9B04-6EDE47CC1D9A'
GO

-- Creating Plan Guide for FORCED parameterization
DECLARE
	@stmt NVARCHAR(MAX)
	,@params NVARCHAR(MAX)
	,@query NVARCHAR(MAX) = N'SELECT TOP 1 OrderId FROM dbo.Orders WHERE CustomerId = ''B970D68B-F88E-438B-9B04-6EDE47CC1D9A''';

EXEC sp_get_query_template
	@querytext = @query
	,@templatetext = @stmt OUTPUT
	,@params = @params OUTPUT;

EXEC sp_create_plan_guide
	@type = N'TEMPLATE'
	,@name = N'forced_parameterization_plan_guide'
	,@stmt = @stmt
	,@module_or_batch = NULL
	,@params = @params
	,@hints = N'OPTION (PARAMETERIZATION FORCED)';
GO

-- The following statement is now using FORCED parameterization auto-parameterized
SELECT TOP 1 OrderId FROM dbo.Orders WHERE CustomerId = 'B970D68B-F88E-438B-9B04-6EDE47CC1D9A'
GO

-- Validating Plan Guide. Empty message indicates that plan guide is valid
SELECT 
	pg.plan_guide_id
	,pg.name
	,pg.scope_type_desc
	,pg.is_disabled
	,vpg.[message]
FROM 
	sys.plan_guides pg WITH (NOLOCK)
		OUTER APPLY 
		(
			SELECT [message]
			FROM sys.fn_validate_plan_guide(pg.plan_guide_id)
		) vpg
OPTION (MAXDOP 1, RECOMPILE);
GO

-- Drop plan guide
EXEC sp_control_plan_guide 
	@operation = N'DROP'
	,@name = N'forced_parameterization_plan_guide';
GO

-- Switching database to FORCED parameterization
-- Setting SIMPLE parameterization
ALTER DATABASE [SQLServerInternals] SET PARAMETERIZATION FORCED;
GO

-- This statement does not use filtered index due to forced parameterization
SELECT OrderId
FROM dbo.Orders
WHERE Fulfilled = 0;
GO

-- Forcing SIMPLE parameterizarion

-- Step 1: Need to get parameterized SQLand parameters based on output below
SELECT
	SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
	((
		CASE qs.statement_end_offset
			WHEN -1 THEN DATALENGTH(qt.text)
			ELSE qs.statement_end_offset
		END - qs.statement_start_offset)/2)+1) AS SQL
	,qt.text AS [Full SQL]
FROM
	sys.dm_exec_query_stats qs WITH (NOLOCK)
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE
	qt.text LIKE '%Fulfilled%'
OPTION(RECOMPILE, MAXDOP 1);

-- Step 2 - creating plan guide
DECLARE
	@stmt NVARCHAR(MAX) = N'select OrderId from dbo . Orders where Fulfilled = @0'
	,@params NVARCHAR(MAX) = N'@0 int'

EXEC sp_create_plan_guide
	@type = N'TEMPLATE'
	,@name = N'simple_parameterization_plan_guide'
	,@stmt = @stmt
	,@module_or_batch = NULL
	,@params = @params
	,@hints = N'OPTION (PARAMETERIZATION SIMPLE)';
GO

-- Now the statement is using SIMPLE parameterization and filtered index
SELECT OrderId
FROM dbo.Orders
WHERE Fulfilled = 0;
GO

-- Validating Plan Guide. Empty message indicates that plan guide is valid
SELECT 
	pg.plan_guide_id
	,pg.name
	,pg.scope_type_desc
	,pg.is_disabled
	,vpg.[message]
FROM 
	sys.plan_guides pg WITH (NOLOCK)
		OUTER APPLY 
		(
			SELECT [message]
			FROM sys.fn_validate_plan_guide(pg.plan_guide_id)
		) vpg
OPTION (MAXDOP 1, RECOMPILE);
GO

-- Drop plan guide
EXEC sp_control_plan_guide 
	@operation = N'DROP'
	,@name = N'simple_parameterization_plan_guide';
GO

-- Setting SIMPLE parameterization
ALTER DATABASE [SQLServerInternals] SET PARAMETERIZATION SIMPLE;
GO