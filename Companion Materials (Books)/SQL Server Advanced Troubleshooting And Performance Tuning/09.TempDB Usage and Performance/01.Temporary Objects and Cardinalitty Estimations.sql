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

USE SQLServerInternals
GO

IF OBJECT_ID(N'tempdb..#TT') IS NOT NULL
	DROP TABLE #TT;
GO

CREATE TABLE #TT(ID INT NOT NULL PRIMARY KEY);

;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 rows
,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N4)
INSERT INTO #TT(ID)
	SELECT ID FROM IDs;
GO

-- Enable "Display Actual Execution Plan" 
-- Check Cardinality Estimations
DECLARE
	@TTV TABLE(ID INT NOT NULL PRIMARY KEY);

INSERT INTO @TTV(ID)
	SELECT ID FROM #TT;

SELECT COUNT(*) FROM #TT; -- 256 estimated rows
SELECT COUNT(*) FROM @TTV; -- 1 estimated row in compatibility level <= 140. 256 estimated rows in compatibility level 150+ due to deferred TV recompile
SELECT COUNT(*) FROM @TTV OPTION (RECOMPILE); -- 77 estimated rows
GO

-- Now with filters
DECLARE
	@TTV TABLE(ID INT NOT NULL PRIMARY KEY);

INSERT INTO @TTV(ID)
	SELECT ID FROM #TT;

SELECT COUNT(*) FROM #TT WHERE ID > 0; -- 256 estimated rows
SELECT COUNT(*) FROM @TTV WHERE ID > 0; -- 1 estimated row in compatibility level <= 140. 77 estimated rows in compatibility level 150+ due to deferred TV recompile
SELECT COUNT(*) FROM @TTV WHERE ID > 0 OPTION (RECOMPILE) -- 77 estimated rows;
GO