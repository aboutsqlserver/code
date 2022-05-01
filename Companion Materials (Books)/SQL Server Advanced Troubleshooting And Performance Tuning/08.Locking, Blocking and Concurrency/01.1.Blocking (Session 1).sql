/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 08: Locking, Blocking and Concurrency               */
/*                     Blocking Condition (Session 1)                       */
/****************************************************************************/

USE SQLServerInternals
GO

IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'Orders') DROP TABLE dbo.Orders;
GO

CREATE TABLE dbo.Orders
(
	OrderId INT NOT NULL,
	OrderNum VARCHAR(32) NOT NULL,
	OrderDate SMALLDATETIME NOT NULL,
	CustomerId INT NOT NULL,
	Amount MONEY NOT NULL,
	OrderStatus INT NOT NULL,
	Placeholder CHAR(400) NULL
);

WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T3) -- 256 rows
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4) -- 65,536 rows
,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)
INSERT INTO dbo.Orders(OrderId,OrderNum,OrderDate,CustomerId,Amount,OrderStatus)
	SELECT ID,CONVERT(VARCHAR(32),ID),DATEADD(DAY,-ID % 365,GETDATE()),ID % 512,ID % 100,0
	FROM IDs;

CREATE UNIQUE CLUSTERED INDEX IDX_Orders_OrderId
ON dbo.Orders(OrderId);
GO

-- Step 1:
BEGIN TRAN
	DELETE FROM dbo.Orders WHERE OrderId = 50;

-- Run the script from Session 2 "01.2.Blocking (Session 2).sql"
-- Don't run ROLLBACK
--ROLLBACK