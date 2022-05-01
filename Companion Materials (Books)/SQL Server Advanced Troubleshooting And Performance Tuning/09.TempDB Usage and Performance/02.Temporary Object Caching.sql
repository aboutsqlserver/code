/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                  Chapter 09: tempdb Usage and Performance                */
/*                            Temporary Objects                             */
/****************************************************************************/

USE tempdb
GO

IF EXISTS(SELECT * FROM sys.procedures p JOIN sys.schemas s ON p.schema_id = s.schema_id WHERE s.name = 'dbo' AND p.name = 'TempTableCaching') DROP PROC dbo.TempTableCaching;
GO

CREATE PROC dbo.TempTableCaching
AS
	CREATE TABLE #T(C INT NOT NULL PRIMARY KEY);
	DROP TABLE #T;
GO


-- Run test twice and analyze # of log records
CHECKPOINT;
GO

EXEC dbo.TempTableCaching;
GO

SELECT
	Operation, Context, AllocUnitName
	,[Transaction Name], [Description]
FROM
	sys.fn_dblog(null, null);
GO