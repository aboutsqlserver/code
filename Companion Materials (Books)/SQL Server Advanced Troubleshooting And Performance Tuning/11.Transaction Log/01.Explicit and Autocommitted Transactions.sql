/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 11: Transaction Log                          */
/*             Explicit and Autocommitted Transactions                      */
/****************************************************************************/

USE SQLServerInternals
GO

IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'TranOverhead') DROP TABLE dbo.TranOverhead;
GO

CREATE TABLE dbo.TranOverhead
(
	Id INT NOT NULL,
	Col CHAR(50) NULL,
	
	CONSTRAINT PK_TranOverhead
		PRIMARY KEY CLUSTERED(Id)
);

-- Auto-committed transactions
DECLARE
	@Id INT = 1
	,@StartTime DATETIME = GETDATE()
	,@num_of_writes BIGINT
	,@num_of_bytes_written BIGINT

SELECT @num_of_writes = num_of_writes, @num_of_bytes_written = num_of_bytes_written
FROM sys.dm_io_virtual_file_stats(db_id(),2);

WHILE @Id <= 10000
BEGIN
	INSERT INTO dbo.TranOverhead(Id, Col) VALUES(@Id, 'A');
	UPDATE dbo.TranOverhead SET Col = 'B' WHERE Id = @Id;
	DELETE FROM dbo.TranOverhead WHERE Id = @Id;
	SET @Id += 1;
END;

SELECT
	DATEDIFF(MILLISECOND,@StartTime,GETDATE())AS [Time(ms): Autocommitted Tran]
	,s.num_of_writes - @num_of_writes AS [Number of writes]
	,(s.num_of_bytes_written - @num_of_bytes_written) / 1024 AS [Bytes written (KB)]
FROM
	sys.dm_io_virtual_file_stats(db_id(),2) s;
GO

-- Explicit Tran
DECLARE
	@Id INT = 1
	,@StartTime DATETIME = GETDATE()
	,@num_of_writes BIGINT
	,@num_of_bytes_written BIGINT

SELECT @num_of_writes = num_of_writes, @num_of_bytes_written = num_of_bytes_written
FROM sys.dm_io_virtual_file_stats(db_id(),2);

WHILE @Id <= 10000
BEGIN
	BEGIN TRAN
		INSERT INTO dbo.TranOverhead(Id, Col) VALUES(@Id, 'A');
		UPDATE dbo.TranOverhead SET Col = 'B' WHERE Id = @Id;
		DELETE FROM dbo.TranOverhead WHERE Id = @Id;
	COMMIT
	SET @Id += 1;
END;

SELECT
	DATEDIFF(MILLISECOND,@StartTime,GETDATE()) AS [Time(ms): Explicit Tran]
	,s.num_of_writes - @num_of_writes AS [Number of writes]
	,(s.num_of_bytes_written - @num_of_bytes_written) / 1024 AS [Bytes written (KB)]
FROM
	sys.dm_io_virtual_file_stats(db_id(),2) s;
GO