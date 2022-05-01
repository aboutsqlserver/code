/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                Chapter 05: Data Storage and Query Tuning                 */
/*                         Nonclustered Index Usage                         */
/****************************************************************************/

USE SQLServerInternals
GO

IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'Books') DROP TABLE dbo.Books;
GO

CREATE TABLE dbo.Books
(
	BookId INT IDENTITY(1,1) NOT NULL,
	Title NVARCHAR(256) NOT NULL,
	-- International Standard Book Number
	ISBN CHAR(14) NOT NULL, 
	Placeholder CHAR(150) NULL
);

CREATE UNIQUE CLUSTERED INDEX IDX_Books_BookId ON dbo.Books(BookId);

-- 1,252,000 rows
;WITH Prefix(Prefix)
AS
(
	SELECT 100 
	UNION ALL
	SELECT Prefix + 1
	FROM Prefix
	WHERE Prefix < 600
)
,Postfix(Postfix)
AS
(
	SELECT 100000001
	UNION ALL
	SELECT Postfix + 1
	FROM Postfix
	WHERE Postfix < 100002500
)
INSERT INTO dbo.Books(ISBN, Title)
	SELECT 
		CONVERT(CHAR(3), Prefix) + '-0' + CONVERT(CHAR(9),Postfix)
		,'Title for ISBN' + CONVERT(CHAR(3), Prefix) + '-0' + CONVERT(CHAR(9),Postfix)
	FROM Prefix CROSS JOIN Postfix
OPTION (MAXRECURSION 0);
GO

CREATE NONCLUSTERED INDEX IDX_Books_ISBN ON dbo.Books(ISBN);
GO

-- Enable "Include Actual Execution Plan". Check logical reads
-- 2,500 rows - SQL Server uses Index Seek + Key Lookup
SET STATISTICS IO ON
SELECT * FROM dbo.Books WHERE ISBN LIKE '210%';
SET STATISTICS IO OFF
GO

-- 7,500 rows - SQL Server uses Index Seek + Key Lookup
SET STATISTICS IO ON
SELECT * FROM dbo.Books WHERE ISBN LIKE '21[0-2]%';
SET STATISTICS IO OFF
GO

-- 12,500 rows - Clustered Index Scan is cheaper
SET STATISTICS IO ON
SELECT * FROM dbo.Books WHERE ISBN LIKE '21[0-4]%';
SELECT * FROM dbo.Books WITH (INDEX = IDX_Books_ISBN) WHERE ISBN LIKE '21[0-4]%';
SET STATISTICS IO OFF
GO
