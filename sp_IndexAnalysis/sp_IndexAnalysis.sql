/****************************************************************************/
/* Troubleshooting Scripts - sp_IndexAnalysis                               */
/*                                                                          */
/* Dmitri V. Korotkevitch (MCM, MVP)                                        */
/* email: dk@aboutsqlserver.com                                             */
/* blog: https://aboutsqlserver.com                                         */
/* code: https://github.com/aboutsqlserver/code                             */
/*                                                                          */
/* SQL Server Advanced Troubleshooting and Performance Tuning               */
/* (O'Reilly, 2022) ISBN: 978-1098101923  ISBN-10: 1098101928               */
/****************************************************************************/
/* The procedure provides multiple index usage and operational metrics      */
/* combining all data into the single holistic view. This includes:         */
/*  - Index Definition and properties                                       */
/*  - Size on-disk and in buffer pool                                       */
/*  - Usage statistics                                                      */
/*  - Operational statistics                                                */
/****************************************************************************/

IF EXISTS(SELECT * FROM sys.procedures p JOIN sys.schemas s ON p.schema_id = s.schema_id WHERE s.name = 'dbo' AND p.name = 'sp_IndexAnalysis') DROP PROC dbo.sp_IndexAnalysis;
GO

CREATE PROC dbo.sp_IndexAnalysis
(
/****************************************************************************/
/* The procedure provides multiple index usage and operational metrics      */
/* combining all data into the single holistic view. This includes:         */
/*  - Index Definition and properties                                       */
/*  - Size on-disk and in buffer pool                                       */
/*  - Usage statistics                                                      */
/*  - Operational statistics                                                */
/*                                                                          */
/* Parameters:                                                              */
/*    - @Databases - Databases to analyze. Possible values:                 */
/*           - CURRENT: Current datanase                                    */
/*           - USER: All user datanases                                     */
/*           - Comma-separated list of database names                       */
/*    - @DestinationTable - Table to save the results                       */
/*           - NULL: Do not save results. Output only                       */
/*           - [DB].[Schema].[Table] formnat                                */
/*    - @CreateDestinationTable - create destination table to save results  */
/*           - @DestinationTable should be provided. Table should not exist */
/*    - @ReturnResultSet - Specifies if SP returns results	                */
/*           - Either (or both) @ReturnResultSet or @DestinationTable       */
/*             should be 1                                                  */
/*    - @IncludeBufferPoolUsage - Specifies if SP should analyze buffer     */
/*      pool memory usage	                                                */
/*           - Time consuming on the servers with large amount of memory    */
/*    - @Verbose - Additional debug information                             */
/* Returns:                                                                 */
/*    - 0 - Success                                                         */
/*    - 1 - Invalid Parameters                                              */
/****************************************************************************/
/* Written by Dmitri V. Korotkevitch (MCM, MVP)                             */
/* email: dk@aboutsqlserver.com                                             */
/* blog: https://aboutsqlserver.com                                         */
/* code: https://github.com/aboutsqlserver/code                             */
/****************************************************************************/
/* Change Log:                                                              */
/*    - 2022-04-29: DK:Initial Commit                                       */
/****************************************************************************/
    @Databases NVARCHAR(4000) = 'CURRENT' 
    ,@DestinationTable SYSNAME = NULL 
    ,@CreateDestinationTable BIT = 0 
    ,@ReturnResultSet BIT = 1 
    ,@IncludeBufferPoolUsage BIT = 1 
    ,@Verbose BIT = 1 
)
AS
BEGIN
    SET NOCOUNT, XACT_ABORT ON
    DECLARE
		@Msg NVARCHAR(4000)
		,@database_id SMALLINT = 0
		,@name SYSNAME
		,@sql NVARCHAR(MAX)
		,@schema SYSNAME 
		,@table SYSNAME
		,@db SYSNAME 
		,@qn_db NVARCHAR(262)
		,@qn_schema NVARCHAR(262)
		,@qn_table NVARCHAR(262)
		,@mem_optimized NVARCHAR(32)

    SET @Databases = LTRIM(RTRIM(ISNULL(@Databases,N'')));
    SET @DestinationTable = LTRIM(RTRIM(ISNULL(@DestinationTable,N'')));
    SET @CreateDestinationTable = ISNULL(@CreateDestinationTable,0);
    SET @ReturnResultSet = ISNULL(@ReturnResultSet,1);
    SET @IncludeBufferPoolUsage = ISNULL(@IncludeBufferPoolUsage,0);
    SET @Verbose = ISNULL(@Verbose,0);

    /* Validating parameter values */
    IF @DestinationTable = N''
    BEGIN
        IF @CreateDestinationTable = 1
        BEGIN
            RAISERROR('Incorrect Parameters: @CreteDestinationTable is 1 but @DestinationTable is blank',10,1) WITH NOWAIT;
			RETURN 1;
        END
        IF @ReturnResultSet = 0   
        BEGIN
            RAISERROR('Incorrect Parameters: @ReturnResultSet is 0 and @DestinationTable is blank. No output can be generated',10,1) WITH NOWAIT;
            RETURN 1;
        END
    END
	ELSE BEGIN
		SELECT
			@schema = PARSENAME(@DestinationTable,2)
			,@table = PARSENAME(@DestinationTable,1)
			,@db = PARSENAME(@DestinationTable,3);
		
		IF @CreateDestinationTable = 1 AND LEFT(@table,1) = '#'
        BEGIN
            RAISERROR('Incorrect Parameters: Cannot create @DestinationTable as temporary table',10,1) WITH NOWAIT;
            RETURN 1;
        END

		IF @table is null
        BEGIN
            RAISERROR('Incorrect Parameters: @DestinationTable is invalid "%s"',10,1,@DestinationTable) WITH NOWAIT;
            RETURN 1;
        END
		
		SET @qn_table = QUOTENAME(@table);

		SET @DestinationTable =
			IIF(@db IS NOT NULL,QUOTENAME(@db) + N'.',N'') + 
			IIF(@schema IS NOT NULL,QUOTENAME(@schema) + N'.',N'') + 
			@qn_table; 
		
		IF @CreateDestinationTable = 0 AND OBJECT_ID(@DestinationTable,'U') IS NULL
        BEGIN
            RAISERROR('Incorrect Parameters: @DestinationTable does not exist "%s"',10,1,@DestinationTable) WITH NOWAIT;
            RETURN 1;
        END
	END

    CREATE TABLE #Databases
    (
        database_id SMALLINT NULL,
		name SYSNAME NOT NULL UNIQUE
    );

    IF UPPER(@Databases) = 'CURRENT'
        INSERT INTO #Databases(database_id, name) 
            SELECT DB_ID(), DB_NAME();
    ELSE IF UPPER(@Databases) = 'USER'
        INSERT INTO #Databases(database_id, name) 
            SELECT database_id, name 
            FROM sys.databases WITH (NOLOCK)
            WHERE database_id > 4 AND database_id <> 32767
    ELSE BEGIN
        DECLARE 
            @db_xml XML = CONVERT(XML,'<r><db>' + REPLACE(@Databases, ',', '</db><db>')+ '</db></r>')
            ,@incorrectDB NVARCHAR(4000) = NULL;
        
		;WITH DBNames(name)
		AS
		(
			SELECT DISTINCT LTRIM(RTRIM(d.n.value('.', 'SYSNAME')))
            FROM @db_xml.nodes('/r/db') d(n)
		)
		INSERT INTO #Databases(database_id, name)
			SELECT d.database_id, n.name
			FROM DBNames n LEFT OUTER JOIN sys.databases d WITH (NOLOCK) ON
				d.name = REPLACE(REPLACE(n.name,'[',''),']',''); 

        ;WITH InvalidDBs(names)
        AS
        (
                SELECT td.name + ',' AS [text()]
                FROM #Databases td
                WHERE database_id IS NULL
                FOR XML PATH('')
        )
        SELECT @incorrectDB = LEFT(names,LEN(names) - 1)
        FROM InvalidDBs;

        IF @incorrectDB IS NOT NULL
        BEGIN
            RAISERROR('Incorrect Parameters: The list of databases is invalid: "%s"',10,1,@incorrectDB) WITH NOWAIT;
            RETURN 1;
        END
    END
	IF @Verbose = 1
	BEGIN
		RAISERROR('Parameters validated',0,1) WITH NOWAIT;

	    ;WITH DBs(names)
        AS
        (
			SELECT td.name + ',' AS [text()]
            FROM #Databases td
            FOR XML PATH('')
        )
        SELECT @Msg = LEFT(names,LEN(names) - 1)
        FROM DBs;	
		RAISERROR('Processing databases: %s',0,1,@Msg) WITH NOWAIT;
		
		IF @DestinationTable <> ''
			RAISERROR('Destination table: %s',0,1,@DestinationTable) WITH NOWAIT;
	END

    CREATE TABLE #Buffs
    (
        db_id INT NOT NULL,
        allocation_unit_id BIGINT NOT NULL,
        size DECIMAL(12,3) NOT NULL,
        PRIMARY KEY(db_id,allocation_unit_id)
    );
   
	CREATE TABLE #Results
	(
		database_id SMALLINT NOT NULL,
		[database] SYSNAME NOT NULL,
		guid BIT NOT NULL,
		object_id INT NOT NULL,
		index_id INT NOT NULL,
		[table] NVARCHAR(1024) NOT NULL,
		[index] SYSNAME NULL,
		[type] NVARCHAR(60) NOT NULL,
		key_columns NVARCHAR(MAX) NULL,
		included_columns NVARCHAR(MAX) NULL,
		[filter] NVARCHAR(MAX) NULL,
		max_key_length INT NULL,
		[rows] BIGINT NULL,
		is_unique BIT NULL,
		is_disabled BIT NULL,
		[lock_escalation] NVARCHAR(60) NOT NULL,
		max_compression VARCHAR(19) NOT NULL,
		total_pages BIGINT NOT NULL,
		used_pages BIGINT NOT NULL,
		data_pages BIGINT NOT NULL,
		total_space_mb DECIMAL(12,3) NOT NULL,
		used_space_mb DECIMAL(12,3) NOT NULL,
		data_space_mb DECIMAL(12,3) NOT NULL,
		buffer_pool_space_mb decimal(38,3) NULL,
		[stats_date] DATETIME NULL,
		user_seeks BIGINT NULL,
		user_scans BIGINT NULL,
		user_lookups BIGINT NULL,
		user_reads BIGINT NULL,
		user_updates BIGINT NULL,
		last_user_seek DATETIME NULL,
		last_user_scan DATETIME NULL,
		last_user_lookup DATETIME NULL,
		last_user_update DATETIME NULL,
		range_scan_count BIGINT NULL,
		singleton_lookup_count BIGINT NULL,
		forwarded_fetch_count BIGINT NULL,
		lob_fetch_in_pages BIGINT NULL,
		row_overflow_fetch_in_pages BIGINT NULL,
		leaf_insert_count BIGINT NULL,
		leaf_update_count BIGINT NULL,
		leaf_delete_count BIGINT NULL,
		leaf_ghost_count BIGINT NULL,
		nonleaf_insert_count BIGINT NULL,
		nonleaf_update_count BIGINT NULL,
		nonleaf_delete_count BIGINT NULL,
		leaf_allocation_count BIGINT NULL,
		nonleaf_allocation_count BIGINT NULL,
		row_lock_count BIGINT NULL,
		row_lock_wait_count BIGINT NULL,
		row_lock_wait_in_ms BIGINT NULL,
		page_lock_count BIGINT NULL,
		page_lock_wait_count BIGINT NULL,
		page_lock_wait_in_ms BIGINT NULL,
		index_lock_promotion_attempt_count BIGINT NULL,
		index_lock_promotion_count BIGINT NULL,
		page_latch_wait_count BIGINT NULL,
		page_latch_wait_in_ms BIGINT NULL,
		tree_page_latch_wait_count BIGINT NULL,
		tree_page_latch_wait_in_ms BIGINT NULL,
		page_io_latch_wait_count BIGINT NULL,
		page_io_latch_wait_in_ms BIGINT NULL,
		page_compression_attempt_count BIGINT NULL,
		page_compression_success_count BIGINT NULL
	);

	CREATE TABLE #OpStats
	(
		database_id SMALLINT NOT NULL,
		object_id INT NOT NULL,
		index_id INT NOT NULL,
		range_scan_count BIGINT NULL,
		singleton_lookup_count BIGINT NULL,
		forwarded_fetch_count BIGINT NULL,
		lob_fetch_in_pages BIGINT NULL,
		row_overflow_fetch_in_pages BIGINT NULL,
		leaf_insert_count BIGINT NULL,
		leaf_update_count BIGINT NULL,
		leaf_delete_count BIGINT NULL,
		leaf_ghost_count BIGINT NULL,
		nonleaf_insert_count BIGINT NULL,
		nonleaf_update_count BIGINT NULL,
		nonleaf_delete_count BIGINT NULL,
		leaf_allocation_count BIGINT NULL,
		nonleaf_allocation_count BIGINT NULL,
		row_lock_count BIGINT NULL,
		row_lock_wait_count BIGINT NULL,
		row_lock_wait_in_ms BIGINT NULL,
		page_lock_count BIGINT NULL,
		page_lock_wait_count BIGINT NULL,
		page_lock_wait_in_ms BIGINT NULL,
		index_lock_promotion_attempt_count BIGINT NULL,
		index_lock_promotion_count BIGINT NULL,
		page_latch_wait_count BIGINT NULL,
		page_latch_wait_in_ms BIGINT NULL,
		tree_page_latch_wait_count BIGINT NULL,
		tree_page_latch_wait_in_ms BIGINT NULL,
		page_io_latch_wait_count BIGINT NULL,
		page_io_latch_wait_in_ms BIGINT NULL,
		page_compression_attempt_count BIGINT NULL,
		page_compression_success_count BIGINT NULL,

		primary key (database_id, object_id, index_id)
	);

	IF CONVERT(INT,
		LEFT
		(
			CONVERT(NVARCHAR(128), SERVERPROPERTY('ProductVersion')),
			CHARINDEX('.',CONVERT(NVARCHAR(128), SERVERPROPERTy('ProductVersion'))) - 1
		)
	) >= 12 -- SQL Server 2014
		SET @mem_optimized = N't.is_memory_optimized = 0 AND ';
	ELSE
		SET @mem_optimized = '';

	IF @CreateDestinationTable = 1
	BEGIN
        IF @Verbose = 1 
        BEGIN   
            SET @Msg = CONVERT(VARCHAR(32),GETDATE(),121) + N' - Creating destination table "%s"';
		    RAISERROR(@Msg,0,1,@DestinationTable) WITH NOWAIT;
        END;
 
		SELECT @sql = CONVERT(NVARCHAR(MAX),N'CREATE TABLE ') + @DestinationTable + N'
(
	[server] NVARCHAR(260) NOT NULL,
	collection_time DATETIME NOT NULL,
	database_id SMALLINT NOT NULL,
	[database] SYSNAME NOT NULL,
	guid BIT NOT NULL,
	object_id INT NOT NULL,
	index_id INT NOT NULL,
	[table] NVARCHAR(1024) NOT NULL,
	[index] SYSNAME NULL,
	[type] NVARCHAR(60) NOT NULL,
	key_columns NVARCHAR(MAX) NULL,
	included_columns NVARCHAR(MAX) NULL,
	[filter] NVARCHAR(MAX) NULL,
	max_key_length INT NULL,
	[rows] BIGINT NULL,
	is_unique BIT NULL,
	is_disabled BIT NULL,
	[lock_escalation] NVARCHAR(60) NOT NULL,
	max_compression VARCHAR(19) NOT NULL,
	total_pages BIGINT NOT NULL,
	used_pages BIGINT NOT NULL,
	data_pages BIGINT NOT NULL,
	total_space_mb DECIMAL(12,3) NOT NULL,
	used_space_mb DECIMAL(12,3) NOT NULL,
	data_space_mb DECIMAL(12,3) NOT NULL,
	buffer_pool_space_mb decimal(38,3) NULL,
	[stats_date] DATETIME NULL,
	user_seeks BIGINT NULL,
	user_scans BIGINT NULL,
	user_lookups BIGINT NULL,
	user_reads BIGINT NULL,
	user_updates BIGINT NULL,
	last_user_seek DATETIME NULL,
	last_user_scan DATETIME NULL,
	last_user_lookup DATETIME NULL,
	last_user_update DATETIME NULL,
	range_scan_count BIGINT NULL,
	singleton_lookup_count BIGINT NULL,
	forwarded_fetch_count BIGINT NULL,
	lob_fetch_in_pages BIGINT NULL,
	row_overflow_fetch_in_pages BIGINT NULL,
	leaf_insert_count BIGINT NULL,
	leaf_update_count BIGINT NULL,
	leaf_delete_count BIGINT NULL,
	leaf_ghost_count BIGINT NULL,
	nonleaf_insert_count BIGINT NULL,
	nonleaf_update_count BIGINT NULL,
	nonleaf_delete_count BIGINT NULL,
	leaf_allocation_count BIGINT NULL,
	nonleaf_allocation_count BIGINT NULL,
	row_lock_count BIGINT NULL,
	row_lock_wait_count BIGINT NULL,
	row_lock_wait_in_ms BIGINT NULL,
	page_lock_count BIGINT NULL,
	page_lock_wait_count BIGINT NULL,
	page_lock_wait_in_ms BIGINT NULL,
	index_lock_promotion_attempt_count BIGINT NULL,
	index_lock_promotion_count BIGINT NULL,
	page_latch_wait_count BIGINT NULL,
	page_latch_wait_in_ms BIGINT NULL,
	tree_page_latch_wait_count BIGINT NULL,
	tree_page_latch_wait_in_ms BIGINT NULL,
	page_io_latch_wait_count BIGINT NULL,
	page_io_latch_wait_in_ms BIGINT NULL,
	page_compression_attempt_count BIGINT NULL,
	page_compression_success_count BIGINT NULL,
	CONSTRAINT [PK_' + RIGHT(@qn_table,LEN(@qn_table) - 1) + N'
	PRIMARY KEY CLUSTERED([server],collection_time,database_id,object_id,index_id)
);
CREATE INDEX [IDX_' + RIGHT(@qn_table,LEN(@qn_table) - 1) + N'
ON ' + @DestinationTable + N'([database],[table],[index]) INCLUDE([server]);';
print @sql;
		
		EXEC sp_executesql @sql;

        IF @Verbose = 1 
        BEGIN   
            SET @Msg = CONVERT(VARCHAR(32),GETDATE(),121) + N' -  Done';
		    RAISERROR(@Msg,0,1) WITH NOWAIT;
        END;
	END

    IF @IncludeBufferPoolUsage = 1
    BEGIN
        IF @Verbose = 1 
        BEGIN   
            SET @Msg = CONVERT(VARCHAR(32),GETDATE(),121) + N' - Populating Buffer Pool Allocation Information';
		    RAISERROR(@Msg,0,1) WITH NOWAIT;
        END;
        INSERT INTO #Buffs(db_id, allocation_unit_id, size)
        	SELECT database_id, allocation_unit_id, CONVERT(DECIMAL(12,3),COUNT(*) / 128.0) 
	        FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
	        GROUP BY database_id, allocation_unit_id
            OPTION (MAXDOP 1)
        IF @Verbose = 1 
        BEGIN   
            SET @Msg = CONVERT(VARCHAR(32),GETDATE(),121) + N' -  Done';
		    RAISERROR(@Msg,0,1) WITH NOWAIT;
        END;
    END;

    IF @Verbose = 1 
    BEGIN   
		SET @Msg = CONVERT(VARCHAR(32),GETDATE(),121) + N' -  Collecting Operational Statistics';
		RAISERROR(@Msg,0,1) WITH NOWAIT;
	END;

	INSERT INTO #OpStats(database_id, object_id,index_id,range_scan_count,singleton_lookup_count
		,forwarded_fetch_count,lob_fetch_in_pages,row_overflow_fetch_in_pages,leaf_insert_count,leaf_update_count
		,leaf_delete_count,leaf_ghost_count,nonleaf_insert_count,nonleaf_update_count
		,nonleaf_delete_count,leaf_allocation_count,nonleaf_allocation_count,row_lock_count
		,row_lock_wait_count,row_lock_wait_in_ms,page_lock_count,page_lock_wait_count
		,page_lock_wait_in_ms,index_lock_promotion_attempt_count,index_lock_promotion_count
		,page_latch_wait_count,page_latch_wait_in_ms,tree_page_latch_wait_count
		,tree_page_latch_wait_in_ms,page_io_latch_wait_count,page_io_latch_wait_in_ms
		,page_compression_attempt_count,page_compression_success_count)
		SELECT 
			os.database_id
			,os.object_id
			,os.index_id
			,SUM(os.range_scan_count) AS range_scan_count
			,SUM(os.singleton_lookup_count) AS singleton_lookup_count
			,SUM(os.forwarded_fetch_count) AS forwarded_fetch_count
			,SUM(os.lob_fetch_in_pages) AS lob_fetch_in_pages
			,SUM(os.row_overflow_fetch_in_pages) AS row_overflow_fetch_in_pages
			,SUM(os.leaf_insert_count) AS leaf_insert_count
			,SUM(os.leaf_update_count) AS leaf_update_count
			,SUM(os.leaf_delete_count) AS leaf_delete_count
			,SUM(os.leaf_ghost_count) AS leaf_ghost_count
			,SUM(os.nonleaf_insert_count) AS nonleaf_insert_count
			,SUM(os.nonleaf_update_count) AS nonleaf_update_count
			,SUM(os.nonleaf_delete_count) AS nonleaf_delete_count
			,SUM(os.leaf_allocation_count) AS leaf_allocation_count
			,SUM(os.nonleaf_allocation_count) AS nonleaf_allocation_count
			,SUM(os.row_lock_count) AS row_lock_count
			,SUM(os.row_lock_wait_count) AS row_lock_wait_count
			,SUM(os.row_lock_wait_in_ms) AS row_lock_wait_in_ms
			,SUM(os.page_lock_count) AS page_lock_count
			,SUM(os.page_lock_wait_count) AS page_lock_wait_count
			,SUM(os.page_lock_wait_in_ms) AS page_lock_wait_in_ms
			,SUM(os.index_lock_promotion_attempt_count) AS index_lock_promotion_attempt_count
			,SUM(os.index_lock_promotion_count) AS index_lock_promotion_count
			,SUM(os.page_latch_wait_count) AS page_latch_wait_count
			,SUM(os.page_latch_wait_in_ms) AS page_latch_wait_in_ms
			,SUM(os.tree_page_latch_wait_count) AS tree_page_latch_wait_count
			,SUM(os.tree_page_latch_wait_in_ms) AS tree_page_latch_wait_in_ms
			,SUM(os.page_io_latch_wait_count) AS page_io_latch_wait_count
			,SUM(os.page_io_latch_wait_in_ms) AS page_io_latch_wait_in_ms
			,SUM(os.page_compression_attempt_count) AS page_compression_attempt_count
			,SUM(os.page_compression_success_count) AS page_compression_success_count
		FROM 
			sys.dm_db_index_operational_stats(NULL,NULL,NULL,0) os
		WHERE
			os.database_id IN (SELECT database_id FROM #Databases)
		GROUP BY 
			os.database_id, os.object_id, os.index_id
		OPTION (MAXDOP 1);
	
	IF @Verbose = 1 
    BEGIN   
		SET @Msg = CONVERT(VARCHAR(32),GETDATE(),121) + N' -  Done';
		RAISERROR(@Msg,0,1) WITH NOWAIT;
	END;

	WHILE 1 = 1
	BEGIN
		SELECT TOP 1 @database_id = database_id, @name = name
		FROM #Databases
		WHERE database_id > @database_id
		ORDER BY database_id;
		
		IF @@ROWCOUNT = 0 
			BREAK;

		IF @Verbose = 1 
		BEGIN   
			SET @Msg = CONVERT(VARCHAR(32),GETDATE(),121) + N' -  Populating database %d - %s';
			RAISERROR(@Msg,0,1,@database_id,@name) WITH NOWAIT;
		END;

		SET @sql = 
			CONVERT(NVARCHAR(MAX),N'USE ') + @name + N'; 
;WITH TableInfo
AS
(
	SELECT 
		t.object_id
		,i.index_id
		,sch.name + ''.'' + t.name AS [table]
		,i.name AS [index]
		,i.type_desc AS [type]
		,SUM(p.[rows]) AS [rows]
		,i.is_unique 
		,i.fill_factor
		,i.is_disabled
		,i.filter_definition AS [filter]
		,t.lock_escalation_desc AS [lock_escalation]
		,CASE MAX(p.data_compression)
			WHEN 0 THEN ''NONE''
			WHEN 1 THEN ''ROW''
			WHEN 2 THEN ''PAGE''
			WHEN 3 THEN ''COLUMNSTORE''
			WHEN 4 THEN ''COLUMNSTORE_ARCHIVE''
		END AS [max_compression]
		,SUM(a.total_pages) AS [total_pages]
		,SUM(a.used_pages) AS [used_pages]
		,SUM(a.data_pages) AS [data_pages]
		,CONVERT(DECIMAL(12,3),SUM(a.total_pages) * 8. / 1024.) AS [total_space_mb]
		,CONVERT(DECIMAL(12,3),SUM(a.used_pages) * 8. / 1024.) AS [used_space_mb]
		,CONVERT(DECIMAL(12,3),SUM(a.data_pages) * 8. / 1024.) AS [data_space_mb]
		,SUM(bi.size) AS [buffer_pool_space_mb]
	FROM 
		sys.tables t WITH (NOLOCK) JOIN sys.indexes i WITH (NOLOCK) ON
			t.object_id = i.object_id
		JOIN sys.partitions p WITH (NOLOCK) ON 
			i.object_id = p.object_id AND i.index_id = p.index_id
		JOIN sys.allocation_units a WITH (NOLOCK) ON 
			p.partition_id = a.container_id
		LEFT JOIN #Buffs bi ON
			bi.db_id = DB_ID() AND 
			a.allocation_unit_id = bi.allocation_unit_id 
		JOIN sys.schemas sch WITH (NOLOCK) ON
			t.schema_id = sch.schema_id
	WHERE
		t.name NOT LIKE ''dt%'' AND
		' + @mem_optimized + N'
		i.object_id > 255 
	GROUP BY
		sch.name, t.name, i.type_desc, i.object_id, i.index_id, i.name, 
		i.is_unique, i.fill_factor, t.lock_escalation_desc,
		t.object_id, i.index_id, i.filter_definition, i.is_disabled
)
INSERT INTO #Results(database_id,[database],guid,object_id,index_id,[table],[index],[type]
	,key_columns,included_columns,[filter],max_key_length,[rows],is_unique,is_disabled
	,[lock_escalation],max_compression,total_pages,used_pages,data_pages,total_space_mb
	,used_space_mb,data_space_mb,buffer_pool_space_mb,[stats_date],user_seeks,user_scans
	,user_lookups,user_reads,user_updates,last_user_seek,last_user_scan,last_user_lookup
	,last_user_update,range_scan_count,singleton_lookup_count,forwarded_fetch_count
	,lob_fetch_in_pages,row_overflow_fetch_in_pages,leaf_insert_count,leaf_update_count
	,leaf_delete_count,leaf_ghost_count,nonleaf_insert_count,nonleaf_update_count
	,nonleaf_delete_count,leaf_allocation_count,nonleaf_allocation_count,row_lock_count
	,row_lock_wait_count,row_lock_wait_in_ms,page_lock_count,page_lock_wait_count
	,page_lock_wait_in_ms,index_lock_promotion_attempt_count,index_lock_promotion_count
	,page_latch_wait_count,page_latch_wait_in_ms,tree_page_latch_wait_count
	,tree_page_latch_wait_in_ms,page_io_latch_wait_count,page_io_latch_wait_in_ms
	,page_compression_attempt_count,page_compression_success_count)
	SELECT 
		DB_ID() 
		,DB_NAME() 
		,ic.guid 
		,ti.object_id
		,ti.index_id
		,ti.[table]
		,ti.[index]
		,ti.[type]
		,LEFT(idx_def.key_col,LEN(idx_def.key_col) - 1) AS [key_columns]
		,LEFT(idx_def.included_col,LEN(idx_def.included_col) - 1) AS [included_columns]
		,ti.filter
		,idx_len.max_key_length
		,ti.rows
		,ti.is_unique
		,ti.is_disabled
		,ti.lock_escalation
		,ti.max_compression
		,ti.total_pages
		,ti.used_pages
		,ti.data_pages
		,ti.total_space_mb
		,ti.used_space_mb
		,ti.data_space_mb
		,ti.buffer_pool_space_mb
		,stats_date(ti.object_id, ti.index_id) as [stats_date]
		,ius.user_seeks
		,ius.user_scans
		,ius.user_lookups
		,ius.user_seeks + ius.user_scans + ius.user_lookups AS [user_reads]
		,ius.user_updates 
		,ius.last_user_seek
		,ius.last_user_scan
		,ius.last_user_lookup
		,ius.last_user_update
		,ios.range_scan_count
		,ios.singleton_lookup_count
		,ios.forwarded_fetch_count
		,ios.lob_fetch_in_pages
		,ios.row_overflow_fetch_in_pages
		,ios.leaf_insert_count
		,ios.leaf_update_count
		,ios.leaf_delete_count
		,ios.leaf_ghost_count
		,ios.nonleaf_insert_count
		,ios.nonleaf_update_count
		,ios.nonleaf_delete_count
		,ios.leaf_allocation_count
		,ios.nonleaf_allocation_count
		,ios.row_lock_count
		,ios.row_lock_wait_count
		,ios.row_lock_wait_in_ms
		,ios.page_lock_count
		,ios.page_lock_wait_count
		,ios.page_lock_wait_in_ms
		,ios.index_lock_promotion_attempt_count
		,ios.index_lock_promotion_count
		,ios.page_latch_wait_count
		,ios.page_latch_wait_in_ms
		,ios.tree_page_latch_wait_count
		,ios.tree_page_latch_wait_in_ms
		,ios.page_io_latch_wait_count
		,ios.page_io_latch_wait_in_ms
		,ios.page_compression_attempt_count
		,ios.page_compression_success_count
	FROM 
		TableInfo ti CROSS APPLY
		(
			SELECT
				CASE
					WHEN EXISTS
					(
						SELECT * 
						FROM 
							sys.index_columns ic WITH (NOLOCK) JOIN sys.columns c WITH (NOLOCK) ON	
								ic.object_id = c.object_id AND
								ic.column_id = c.column_id  
						WHERE 
							ic.object_id = ti.object_id AND 
							ic.index_id = ti.index_id AND 
							c.system_type_id = 36 --uniqueidentifier
					)
					THEN 1
					ELSE 0
				END AS [guid]
		) ic  
		OUTER APPLY
		(
			SELECT 
				ius.user_seeks
				,ius.user_scans
				,ius.user_lookups
				,ius.user_updates 
				,ius.last_user_seek
				,ius.last_user_scan
				,ius.last_user_lookup
				,ius.last_user_update
			FROM 
				sys.dm_db_index_usage_stats ius WITH (NOLOCK)
			WHERE
				ius.database_id = DB_ID() AND
				ius.object_id = ti.object_id AND 
				ius.index_id = ti.index_id
		) ius
		LEFT OUTER JOIN #OpStats ios ON
			ti.object_id = ios.object_id AND
			ti.index_id = ios.index_id AND
			ios.database_id = DB_ID()
		CROSS APPLY
		(
			SELECT
				(
					SELECT 
						col.name AS [text()]
						,IIF(icol_meta.is_descending_key = 1, '' DESC'','''') AS [text()]
						,'','' AS [text()]
					FROM
						sys.index_columns icol_meta WITH (NOLOCK)
							JOIN sys.columns col WITH (NOLOCK) ON
								icol_meta.object_id = col.object_id AND
								icol_meta.column_id = col.column_id
					WHERE
						icol_meta.object_id = ti.object_id AND
						icol_meta.index_id = ti.index_id AND
						icol_meta.is_included_column = 0
					ORDER BY
						icol_meta.key_ordinal
					FOR XML PATH('''')
				) AS key_col
				,(                
					SELECT 
						col.name AS [text()]
						,'','' AS [text()]
					FROM                 
						sys.index_columns icol_meta WITH (NOLOCK) 
							JOIN sys.columns col WITH (NOLOCK) ON
								icol_meta.object_id = col.object_id AND
								icol_meta.column_id = col.column_id
					WHERE
						icol_meta.object_id = ti.object_id AND
						icol_meta.index_id = ti.index_id AND
						icol_meta.is_included_column = 1
					ORDER BY
						col.name
					FOR XML PATH('''')
				) AS included_col
			) idx_def
			CROSS APPLY
			(
				SELECT SUM(c.max_length) AS max_key_length
				FROM 
					sys.index_columns ic WITH (NOLOCK) 
						JOIN sys.columns c WITH (NOLOCK) ON
							ic.object_id = c.object_id AND
							ic.column_id = c.column_id
				WHERE 
					ic.object_id = ti.object_id AND
					ic.index_id = ti.index_id AND
					ic.is_included_column = 0
			) idx_len
OPTION (RECOMPILE, MAXDOP 1);';

		exec sp_executesql @sql;

		IF @Verbose = 1 
		BEGIN   
			SET @Msg = CONVERT(VARCHAR(32),GETDATE(),121) + N' -  Done';
			RAISERROR(@Msg,0,1) WITH NOWAIT;
		END;
	END

	IF @DestinationTable <> ''
	BEGIN
        IF @Verbose = 1 
        BEGIN   
            SET @Msg = CONVERT(VARCHAR(32),GETDATE(),121) + N' - Writing data to destination table %s';
		    RAISERROR(@Msg,0,1,@DestinationTable) WITH NOWAIT;
        END;

		SELECT @sql = 
			CONVERT(NVARCHAR(MAX),N'INSERT INTO ') + @DestinationTable + 
N'([server],collection_time,database_id,[database],guid,object_id,index_id,[table],[index],[type]
	,key_columns,included_columns,[filter],max_key_length,[rows],is_unique,is_disabled
	,[lock_escalation],max_compression,total_pages,used_pages,data_pages,total_space_mb
	,used_space_mb,data_space_mb,buffer_pool_space_mb,[stats_date],user_seeks,user_scans
	,user_lookups,user_reads,user_updates,last_user_seek,last_user_scan,last_user_lookup
	,last_user_update,range_scan_count,singleton_lookup_count,forwarded_fetch_count
	,lob_fetch_in_pages,row_overflow_fetch_in_pages,leaf_insert_count,leaf_update_count
	,leaf_delete_count,leaf_ghost_count,nonleaf_insert_count,nonleaf_update_count
	,nonleaf_delete_count,leaf_allocation_count,nonleaf_allocation_count,row_lock_count
	,row_lock_wait_count,row_lock_wait_in_ms,page_lock_count,page_lock_wait_count
	,page_lock_wait_in_ms,index_lock_promotion_attempt_count,index_lock_promotion_count
	,page_latch_wait_count,page_latch_wait_in_ms,tree_page_latch_wait_count
	,tree_page_latch_wait_in_ms,page_io_latch_wait_count,page_io_latch_wait_in_ms
	,page_compression_attempt_count,page_compression_success_count)
		SELECT @@SERVERNAME, GETDATE(), database_id,[database],guid,object_id,index_id,[table],[index],[type]
			,key_columns,included_columns,[filter],max_key_length,[rows],is_unique,is_disabled
			,[lock_escalation],max_compression,total_pages,used_pages,data_pages,total_space_mb
			,used_space_mb,data_space_mb,buffer_pool_space_mb,[stats_date],user_seeks,user_scans
			,user_lookups,user_reads,user_updates,last_user_seek,last_user_scan,last_user_lookup
			,last_user_update,range_scan_count,singleton_lookup_count,forwarded_fetch_count
			,lob_fetch_in_pages,row_overflow_fetch_in_pages,leaf_insert_count,leaf_update_count
			,leaf_delete_count,leaf_ghost_count,nonleaf_insert_count,nonleaf_update_count
			,nonleaf_delete_count,leaf_allocation_count,nonleaf_allocation_count,row_lock_count
			,row_lock_wait_count,row_lock_wait_in_ms,page_lock_count,page_lock_wait_count
			,page_lock_wait_in_ms,index_lock_promotion_attempt_count,index_lock_promotion_count
			,page_latch_wait_count,page_latch_wait_in_ms,tree_page_latch_wait_count
			,tree_page_latch_wait_in_ms,page_io_latch_wait_count,page_io_latch_wait_in_ms
			,page_compression_attempt_count,page_compression_success_count
		FROM #Results';
	
		EXEC sp_executesql @sql;

        IF @Verbose = 1 
        BEGIN   
            SET @Msg = CONVERT(VARCHAR(32),GETDATE(),121) + N' -  Done';
		    RAISERROR(@Msg,0,1) WITH NOWAIT;
        END;
	END

	IF @ReturnResultSet = 1
	BEGIN
		SELECT @@SERVERNAME AS [server], GETDATE() AS collection_time, * 
		FROM #Results 
		ORDER BY [rows] DESC;
	END

    IF @Verbose = 1 
    BEGIN   
		SET @Msg = CONVERT(VARCHAR(32),GETDATE(),121) + N' -  SP Execution completed';
		RAISERROR(@Msg,0,1) WITH NOWAIT;
    END;

	RETURN 0;
END
GO
