/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                Chapter 05: Data Storage and Query Tuning                 */
/*                           Optimization Demo                              */
/****************************************************************************/

USE SQLServerInternals
GO

IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'Customers') DROP TABLE dbo.Customers;
IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'Orders') DROP TABLE dbo.Orders;
GO

CREATE TABLE dbo.Customers
(
	CustomerId INT NOT NULL,
	CustomerName nvarchar(64) NOT NULL,
	CustomerNumber nvarchar(12) NOT NULL,
	Active BIT NOT NULL,
	Street NVARCHAR(32), 
	City NVARCHAR(32),
	[State] CHAR(2),
	ZipCode CHAR(5),
	CreateDate DATETIME NOT NULL
		CONSTRAINT DEF_Customers_CreateDate
		DEFAULT GETUTCDATE(),
);

CREATE UNIQUE CLUSTERED INDEX IDX_Customers_CustomerID
ON dbo.Customers(CustomerId);

CREATE TABLE dbo.Orders
(
	OrderId INT NOT NULL,
	OrderDate DATETIME NOT NULL,
	Amount MONEY NOT NULL,
	CustomerId INT NOT NULL,
	Fulfilled BIT NOT NULL,
	Description NVARCHAR(MAX)
);

CREATE UNIQUE CLUSTERED INDEX IDX_Orders_OrderId
ON dbo.Orders(OrderId);
GO

;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 ROWS
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 ROWS
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 ROWS
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 ROWS
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 ROWS
,IDS(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)
INSERT INTO dbo.Customers(CustomerId, CustomerName, CustomerNumber, Active, Street, City, State, ZipCode)
	SELECT 
		ID, 'Customer ' + CONVERT(NVARCHAR(32),ID), CONVERT(NVARCHAR(32),ID)
		,1,'Street', 'City', IIF(ID % 1000 = 0,'FL','MA'), ID
	FROM IDS;

;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 ROWS
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 ROWS
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 ROWS
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 ROWS
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 ROWS
,IDS(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)
INSERT INTo dbo.Orders(OrderId, OrderDate, Amount, CustomerId, Fulfilled)
	SELECT ID, DATEADD(DAY,ID % 365,'2021-01-01'), ID, ID % 65536, 1
	FROM IDS;
GO

SET STATISTICS IO ON
-- Enable "Display Actial Execution Plan"
DECLARE
	@CustNum NVARCHAR(12) = '1000',
	@StartDate DATETIME = '2021-09-01',
	@EndDate DATETIME = '2021-11-01'

SELECT c.CustomerName, c.CustomerNumber, o.OrderId, o.OrderDate, o.Amount 
FROM  
    dbo.Customers c JOIN dbo.Orders o ON 
        c.CustomerId = o.CustomerId 
WHERE  
    c.CustomerNumber = @CustNum AND 
    c.Active = 1 AND 
    o.OrderDate BETWEEN @StartDate AND @EndDate AND 
    o.Fulfilled = 1
OPTION (MAXDOP 1);
GO

CREATE UNIQUE INDEX IDX_Customers_CustomerNumber ON dbo.Customers(CustomerNumber) INCLUDE (Active, CustomerName)
GO

DECLARE
	@CustNum NVARCHAR(12) = '1000',
	@StartDate DATETIME = '2021-09-01',
	@EndDate DATETIME = '2021-11-01'

SELECT c.CustomerName, c.CustomerNumber, o.OrderId, o.OrderDate, o.Amount 
FROM  
    dbo.Customers c JOIN dbo.Orders o ON 
        c.CustomerId = o.CustomerId 
WHERE  
    c.CustomerNumber = @CustNum AND 
    c.Active = 1 AND 
    o.OrderDate BETWEEN @StartDate AND @EndDate AND 
    o.Fulfilled = 1
OPTION (MAXDOP 1);
GO

CREATE INDEX IDX_Orders_CustomerId_OrderDate ON dbo.Orders(CustomerId, OrderDate) INCLUDE (Fulfilled, Amount)
GO

DECLARE
	@CustNum NVARCHAR(12) = '1000',
	@StartDate DATETIME = '2021-09-01',
	@EndDate DATETIME = '2021-11-01'

SELECT c.CustomerName, c.CustomerNumber, o.OrderId, o.OrderDate, o.Amount 
FROM  
    dbo.Customers c JOIN dbo.Orders o ON 
        c.CustomerId = o.CustomerId 
WHERE  
    c.CustomerNumber = @CustNum AND 
    c.Active = 1 AND 
    o.OrderDate BETWEEN @StartDate AND @EndDate AND 
    o.Fulfilled = 1
OPTION (MAXDOP 1);
GO

SET STATISTICS IO OFF

