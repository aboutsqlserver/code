/*************************************************************************/
/* See https://github.com/aboutsqlserver/code/tree/main/sp_IndexAnalysis */
/*************************************************************************/
EXEC master.dbo.sp_IndexAnalysis
    @Databases = 'CURRENT' 
    ,@DestinationTable = NULL 
    ,@CreateDestinationTable = 0 
    ,@ReturnResultSet = 1 
    ,@IncludeBufferPoolUsage = 1 
    ,@Verbose = 0 