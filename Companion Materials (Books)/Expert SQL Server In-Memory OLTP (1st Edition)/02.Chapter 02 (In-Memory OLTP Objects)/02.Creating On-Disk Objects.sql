/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 02: In-Memory OLTP Objects                       */
/*                     02.Creating On-Disk Objects                          */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

/****************************************************************************/
/*         Scripts in this chapter prepare the database schema for          */
/*                   LogRequestsGenerator demo app                          */
/****************************************************************************/

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertRequestInfo_Disk' and s.name = 'dbo') drop proc dbo.InsertRequestInfo_Disk;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'WebRequests_Disk' and s.name = 'dbo') drop table dbo.WebRequests_Disk;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'WebRequestHeaders_Disk' and s.name = 'dbo') drop table dbo.WebRequestHeaders_Disk;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'WebRequestParams_Disk' and s.name = 'dbo') drop table dbo.WebRequestParams_Disk;
go

create table dbo.WebRequests_Disk
(
	RequestId int not null identity(1,1),
	RequestTime datetime2(4) not null
		constraint DEF_WebRequests_Disk_RequestTime
		default sysutcdatetime(),
	URL varchar(255) not null,
	RequestType tinyint not null, -- GET/POST/PUT
	ClientIP varchar(15) not null,
	BytesReceived int not null,
	
	constraint PK_WebRequests_Disk
	primary key nonclustered(RequestID)
	on [LOGDATA]
) on [LOGDATA]
go

create unique clustered index IDX_WebRequests_Disk_RequestTime_RequestId
on dbo.WebRequests_Disk(RequestTime,RequestId)
on [LOGDATA]
go

/* Foreign Keys have not been defined to make on-disk and memory-optimized tables
as similar as possible */
create table dbo.WebRequestHeaders_Disk
(
	RequestId int not null,
	HeaderName varchar(64) not null,
	HeaderValue varchar(256) not null,
	
	constraint PK_WebRequestHeaders_Disk
	primary key clustered(RequestID,HeaderName)
	on [LOGDATA]
) 
go

create table dbo.WebRequestParams_Disk
(
	RequestId int not null,
	ParamName varchar(64) not null,
	ParamValue nvarchar(256) not null,
	
	constraint PK_WebRequestParams_Disk
	primary key clustered(RequestID,ParamName)
	on [LOGDATA]
) 
go

create proc dbo.InsertRequestInfo_Disk
(
	@URL varchar(255)
	,@RequestType tinyint
	,@ClientIP varchar(15)
	,@BytesReceived int
	-- Header fields
	,@Authorization varchar(256)
	,@UserAgent varchar(256)
	,@Host varchar(256)
	,@Connection varchar(256)
	,@Referer varchar(256)
	-- Parameters.. Just for the demo purposes
	,@Param1 varchar(64) = null
	,@Param1Value nvarchar(256) = null
	,@Param2 varchar(64) = null
	,@Param2Value nvarchar(256) = null
	,@Param3 varchar(64) = null
	,@Param3Value nvarchar(256) = null
	,@Param4 varchar(64) = null
	,@Param4Value nvarchar(256) = null
	,@Param5 varchar(64) = null
	,@Param5Value nvarchar(256) = null
)
as
begin
	set nocount on
	set xact_abort on

	declare
		@RequestId int

	begin tran
		insert into dbo.WebRequests_Disk
			(URL,RequestType,ClientIP,BytesReceived)
		values
			(@URL,@RequestType,@ClientIP,@BytesReceived);

		select @RequestId = SCOPE_IDENTITY();

		insert into dbo.WebRequestHeaders_Disk
			(RequestId,HeaderName,HeaderValue)
		values
			(@RequestId,'AUTHORIZATION',@Authorization)
			,(@RequestId,'USERAGENT',@UserAgent)
			,(@RequestId,'HOST',@Host)
			,(@RequestId,'CONNECTION',@Connection)
			,(@RequestId,'REFERER',@Referer);
		
		;with Params(ParamName, ParamValue)
		as
		(
			select ParamName, ParamValue
			from (
				values
					(@Param1, @Param1Value)
					,(@Param2, @Param2Value)
					,(@Param3, @Param3Value)
					,(@Param4, @Param4Value)
					,(@Param5, @Param5Value)
				) v(ParamName, ParamValue)
			where
				ParamName is not null and
				ParamValue is not null
		)
		insert into dbo.WebRequestParams_Disk
				(RequestID,ParamName,ParamValue)						
			select @RequestId, ParamName, ParamValue
			from Params;
	commit
end
go

