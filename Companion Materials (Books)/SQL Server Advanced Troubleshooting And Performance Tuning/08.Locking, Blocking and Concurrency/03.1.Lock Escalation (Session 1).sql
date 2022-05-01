/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 08: Locking, Blocking and Concurrency               */
/*                       Lock Escalation (Session 1)                        */
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

-- Release Lock Manager memory – do not run on production server!
-- DBCC FREESYSTEMCACHE('ALL');
GO

-- Disabling Lock Escalation
ALTER TABLE dbo.Orders SET (LOCK_ESCALATION = DISABLE);
GO

-- Lock Escalation is disabled
DECLARE
	@C int;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRAN
	SELECT @C = COUNT(*) 
	FROM dbo.Orders WITH (ROWLOCK);

	SELECT
	(
		SELECT COUNT(*)
		FROM sys.dm_tran_locks WITH (NOLOCK)
		WHERE request_session_id = @@SPID
	) AS [Lock Count]
	,(
		SELECT SUM(pages_kb)
		FROM sys.dm_os_memory_clerks WITH (NOLOCK)
		WHERE [type] = 'OBJECTSTORE_LOCK_MANAGER'
	) AS [Memory, KB]

	-- Run Session 2 script "03.2.Lock Escalation (Session 2).sql"
--ROLLBACK;
GO

-- Enable Lock Escalation
ALTER TABLE dbo.Orders SET (LOCK_ESCALATION = AUTO);
GO

-- Lock Escalation is enabled
DECLARE
	@C int;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRAN
	SELECT @C = COUNT(*) 
	FROM dbo.Orders WITH (ROWLOCK);

	SELECT
	(
		SELECT COUNT(*)
		FROM sys.dm_tran_locks WITH (NOLOCK)
		WHERE request_session_id = @@SPID
	) AS [Lock Count]
	,(
		SELECT SUM(pages_kb)
		FROM sys.dm_os_memory_clerks WITH (NOLOCK)
		WHERE [type] = 'OBJECTSTORE_LOCK_MANAGER'
	) AS [Memory, KB]

	-- Run Session 2 script "03.2.Lock Escalation (Session 2).sql"
--ROLLBACK;
GO