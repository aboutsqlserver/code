/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                            Chapter 10: Latches                           */
/*						            Hotspots                                */
/****************************************************************************/


/****************************************************************************/
/*  Use LogRequestsGenerator application to emulate client activity.        */
/*	Choose "dbo.InsertRequestInfo_Disk" mode                                */
/****************************************************************************/

USE SQLServerInternals
GO

IF EXISTS(SELECT * FROM sys.procedures p JOIN sys.schemas s ON p.schema_id = s.schema_id WHERE s.name = 'dbo' AND p.name = 'InsertRequestInfo_Disk') DROP PROC dbo.InsertRequestInfo_Disk;
IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'WebRequests_Disk') DROP TABLE dbo.WebRequests_Disk;
IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'WebRequestHeaders_Disk') DROP TABLE dbo.WebRequestHeaders_Disk;
IF EXISTS(SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'WebRequestParams_Disk') DROP TABLE dbo.WebRequestParams_Disk;
GO

CREATE TABLE dbo.WebRequests_Disk
(
	RequestId INT NOT NULL identity(1,1),
	RequestTime DATETIME2(4) NOT NULL
		CONSTRAINT DEF_WebRequests_Disk_RequestTime
		DEFAULT SYSUTCDATETIME(),
	URL VARCHAR(255) NOT NULL,
	RequestType TINYINT NOT NULL,
	ClientIP VARCHAR(15) NOT NULL,
	BytesReceived INT NOT NULL,
	CONSTRAINT PK_WebRequests_Disk
	PRIMARY KEY NONCLUSTERED(RequestId)
);

CREATE UNIQUE CLUSTERED INDEX IDX_WebRequests_Disk_RequestTime_RequestId
ON dbo.WebRequests_Disk(RequestTime,RequestId);

CREATE TABLE dbo.WebRequestHeaders_Disk
(
	RequestId INT NOT NULL,
	HeaderName VARCHAR(64) NOT NULL,
	HeaderValue VARCHAR(256) NOT NULL,
	CONSTRAINT PK_WebRequestHeaders_Disk
	PRIMARY KEY CLUSTERED(RequestId,HeaderName)
);

CREATE TABLE dbo.WebRequestParams_Disk
(
	RequestId INT NOT NULL,
	ParamName VARCHAR(64) NOT NULL,
	ParamValue NVARCHAR(256) NOT NULL,
	CONSTRAINT PK_WebRequestParams_Disk
	PRIMARY KEY CLUSTERED(RequestId,ParamName)
);
GO

CREATE PROC dbo.InsertRequestInfo_Disk
(
	@URL VARCHAR(255)
	,@RequestType TINYINT
	,@ClientIP VARCHAR(15)
	,@BytesReceived INT
	-- Header fields
	,@Authorization VARCHAR(256)
	,@UserAgent VARCHAR(256)
	,@Host VARCHAR(256)
	,@Connection VARCHAR(256)
	,@Referer VARCHAR(256)
	-- Parameters.. Just for the demo purposes
	,@Param1 VARCHAR(64) = NULL
	,@Param1Value NVARCHAR(256) = NULL
	,@Param2 VARCHAR(64) = NULL
	,@Param2Value NVARCHAR(256) = NULL
	,@Param3 VARCHAR(64) = NULL
	,@Param3Value NVARCHAR(256) = NULL
	,@Param4 VARCHAR(64) = NULL
	,@Param4Value NVARCHAR(256) = NULL
	,@Param5 VARCHAR(64) = NULL
	,@Param5Value NVARCHAR(256) = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE
		@RequestId INT

	BEGIN TRAN
		INSERT INTO dbo.WebRequests_Disk(URL,RequestType,ClientIP,BytesReceived)
		VALUES(@URL,@RequestType,@ClientIP,@BytesReceived);

		SELECT @RequestId = SCOPE_IDENTITY();

		INSERT INTO dbo.WebRequestHeaders_Disk(RequestId,HeaderName,HeaderValue)
		VALUES
			(@RequestId,'AUTHORIZATION',@Authorization)
			,(@RequestId,'USERAGENT',@UserAgent)
			,(@RequestId,'HOST',@Host)
			,(@RequestId,'CONNECTION',@Connection)
			,(@RequestId,'REFERER',@Referer);
		
		;WITH Params(ParamName, ParamValue)
		AS
		(
			SELECT ParamName, ParamValue
			FROM (
				VALUES
					(@Param1, @Param1Value)
					,(@Param2, @Param2Value)
					,(@Param3, @Param3Value)
					,(@Param4, @Param4Value)
					,(@Param5, @Param5Value)
				) v(ParamName, ParamValue)
			WHERE
				ParamName IS NOT NULL AND
				ParamValue IS NOT NULL
		)
		INSERT INTO dbo.WebRequestParams_Disk(RequestId,ParamName,ParamValue)						
			SELECT @RequestId, ParamName, ParamValue
			FROM Params;
	COMMIT
END
GO

-- Run the test in the application
-- Check Wait Statistics

-- Latch statistics for the indexes
SELECT
	s.name + '.' + t.name AS [table]
	,i.index_id
	,i.name AS [index]
	,SUM(os.page_latch_wait_count) AS [latch count]
	,SUM(os.page_latch_wait_in_ms) AS [latch wait (ms)]
FROM
	sys.indexes i WITH (NOLOCK) JOIN sys.tables t WITH (NOLOCK) on
		i.object_id = t.object_id
	JOIN sys.schemas s WITH (NOLOCK) ON
		t.schema_id = s.schema_id
	CROSS APPLY
		sys.dm_db_index_operational_stats
		(
			DB_ID()
			,t.object_id
			,i.index_id
			,0
		) os
GROUP BY
	s.name, t.name, i.name, i.index_id
ORDER BY
	SUM(os.page_latch_wait_in_ms) DESC;
GO

-- Optimize for sequential key (SQL Server 2019+)
ALTER INDEX PK_WebRequestHeaders_Disk
ON dbo.WebRequestHeaders_Disk
SET (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON);

ALTER INDEX PK_WebRequestParams_Disk
ON dbo.WebRequestParams_Disk
SET (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON);
GO


