/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 08: Locking, Blocking and Concurrency               */
/*                      Rov Versioning and Fragmentation                    */
/****************************************************************************/

-- The script is using tempdb to demonstrate that behavior is not db-setting specific
USE tempdb
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
	Placeholder VARCHAR(MAX) NULL -- Need to have LOB column
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
GO

CREATE UNIQUE CLUSTERED INDEX IDX_Orders_OrderId
ON dbo.Orders(OrderId);
GO

-- Check page_count and fragmentation 
SELECT 
	   alloc_unit_type_desc AS [alloc_unit],
       index_level, 
       page_count, 
       CONVERT(DECIMAL(5,2),avg_page_space_used_in_percent) AS [space_used], 
       CONVERT(DECIMAL(5,2),avg_fragmentation_in_percent) AS [frag %],
       min_record_size_in_bytes as [min_size],
       max_record_size_in_bytes as [max_size],
       avg_record_size_in_bytes as [avg_size]
FROM 
	sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Orders'),1,NULL,'DETAILED');
GO

-- Deletion does not increase the size as no row versioning is used
BEGIN TRAN
	DELETE FROM dbo.Orders WHERE OrderId % 2 = 0;

-- Check page_count and fragmentation 
	SELECT 
		   alloc_unit_type_desc AS [alloc_unit],
		   index_level, 
		   page_count, 
		   CONVERT(DECIMAL(5,2),avg_page_space_used_in_percent) AS [space_used], 
		   CONVERT(DECIMAL(5,2),avg_fragmentation_in_percent) AS [frag %],
		   min_record_size_in_bytes as [min_size],
		   max_record_size_in_bytes as [max_size],
		   avg_record_size_in_bytes as [avg_size]
	FROM 
		sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Orders'),1,NULL,'DETAILED');
ROLLBACK
GO

CREATE TRIGGER trgAfterDelete
ON dbo.Orders
AFTER DELETE
AS
	RETURN;
GO

-- Now we have row-versioning due to the trigger
BEGIN TRAN
	DELETE FROM dbo.Orders WHERE OrderId % 2 = 0;

	-- Check page_count and fragmentation 
	SELECT 
		   alloc_unit_type_desc AS [alloc_unit],
		   index_level, 
		   page_count, 
		   CONVERT(DECIMAL(5,2),avg_page_space_used_in_percent) AS [space_used], 
		   CONVERT(DECIMAL(5,2),avg_fragmentation_in_percent) AS [frag %],
		   min_record_size_in_bytes as [min_size],
		   max_record_size_in_bytes as [max_size],
		   avg_record_size_in_bytes as [avg_size]
	FROM 
		sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Orders'),1,NULL,'DETAILED');
ROLLBACK
GO

-- Same applies to in-place update of fixed-length data types

ALTER INDEX IDX_Orders_OrderId ON dbo.Orders REBUILD
GO

-- Check page_count and fragmentation 
SELECT 
	   alloc_unit_type_desc AS [alloc_unit],
       index_level, 
       page_count, 
       CONVERT(DECIMAL(5,2),avg_page_space_used_in_percent) AS [space_used], 
       CONVERT(DECIMAL(5,2),avg_fragmentation_in_percent) AS [frag %],
       min_record_size_in_bytes as [min_size],
       max_record_size_in_bytes as [max_size],
       avg_record_size_in_bytes as [avg_size]
FROM 
	sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Orders'),1,NULL,'DETAILED');
GO

-- Update does not increase the size as no row versioning is used
BEGIN TRAN
	UPDATE dbo.Orders SET Amount += 1;

-- Check page_count and fragmentation 
	SELECT 
		   alloc_unit_type_desc AS [alloc_unit],
		   index_level, 
		   page_count, 
		   CONVERT(DECIMAL(5,2),avg_page_space_used_in_percent) AS [space_used], 
		   CONVERT(DECIMAL(5,2),avg_fragmentation_in_percent) AS [frag %],
		   min_record_size_in_bytes as [min_size],
		   max_record_size_in_bytes as [max_size],
		   avg_record_size_in_bytes as [avg_size]
	FROM 
		sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Orders'),1,NULL,'DETAILED');
ROLLBACK
GO

CREATE TRIGGER trgAfterUpdate
ON dbo.Orders
AFTER UPDATE
AS
	RETURN;
GO

-- Now we have row-versioning due to the trigger
BEGIN TRAN
	UPDATE dbo.Orders SET Amount += 1;

	-- Check page_count and fragmentation 
	SELECT 
		   alloc_unit_type_desc AS [alloc_unit],
		   index_level, 
		   page_count, 
		   CONVERT(DECIMAL(5,2),avg_page_space_used_in_percent) AS [space_used], 
		   CONVERT(DECIMAL(5,2),avg_fragmentation_in_percent) AS [frag %],
		   min_record_size_in_bytes as [min_size],
		   max_record_size_in_bytes as [max_size],
		   avg_record_size_in_bytes as [avg_size]
	FROM 
		sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Orders'),1,NULL,'DETAILED');
ROLLBACK
GO