/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 02: In-Memory OLTP Objects                       */
/*                01.Creating Memory-Optimized Objects                      */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go


/****************************************************************************/
/*         Scripts in this chapter prepare the database schema for          */
/*                   LogRequestsGenerator demo app                          */
/****************************************************************************/


if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertRequestInfo_Memory' and s.name = 'dbo') drop proc dbo.InsertRequestInfo_Memory;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertRequestInfo_NativelyCompiled' and s.name = 'dbo') drop proc dbo.InsertRequestInfo_NativelyCompiled;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'WebRequests_Memory' and s.name = 'dbo') drop table dbo.WebRequests_Memory;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'WebRequestHeaders_Memory' and s.name = 'dbo') drop table dbo.WebRequestHeaders_Memory;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'WebRequestParams_Memory' and s.name = 'dbo') drop table dbo.WebRequestParams_Memory;
go

create table dbo.WebRequests_Memory
(
	RequestId int not null identity(1,1)
		primary key nonclustered 
		hash with (bucket_count=262144),
	RequestTime datetime2(4) not null
		constraint DEF_WebRequests_Memory_RequestTime
		default sysutcdatetime(),
	URL varchar(255) not null,
	RequestType tinyint not null, -- GET/POST/PUT
	ClientIP varchar(15) 
		collate Latin1_General_100_BIN2 not null,
	BytesReceived int not null,
	
	index IDX_RequestTime nonclustered(RequestTime)
) 
with (memory_optimized=on, durability=schema_and_data)
go

create table dbo.WebRequestHeaders_Memory
(
	RequestHeaderId int not null identity(1,1)
		primary key nonclustered 
		hash with (bucket_count=2097152),
	RequestId int not null,
	HeaderName varchar(64) not null,
	HeaderValue varchar(256) not null,
	
	index IDX_RequestID nonclustered hash(RequestID)
	with (bucket_count=262144)
) 
with (memory_optimized=on, durability=schema_and_data)
go

create table dbo.WebRequestParams_Memory
(
	RequestParamId int not null identity(1,1)
		primary key nonclustered 
		hash with (bucket_count=2097152),
	RequestId int not null,
	ParamName varchar(64) not null,
	ParamValue nvarchar(256) not null,
	
	index IDX_RequestID nonclustered hash(RequestID)
	with (bucket_count=262144)
) 
with (memory_optimized=on, durability=schema_and_data)
go

create proc dbo.InsertRequestInfo_Memory
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
		insert into dbo.WebRequests_Memory
			(URL,RequestType,ClientIP,BytesReceived)
		values
			(@URL,@RequestType,@ClientIP,@BytesReceived);

		select @RequestId = SCOPE_IDENTITY();

		insert into dbo.WebRequestHeaders_Memory
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
		insert into dbo.WebRequestParams_Memory
				(RequestID,ParamName,ParamValue)						
			select @RequestID, ParamName, ParamValue
			from Params;
	commit
end
go


create proc dbo.InsertRequestInfo_NativelyCompiled
(
	@URL varchar(255) not null
	,@RequestType tinyint not null
	,@ClientIP varchar(15) not null
	,@BytesReceived int not null
	-- Header fields
	,@Authorization varchar(256) not null
	,@UserAgent varchar(256) not null
	,@Host varchar(256) not null
	,@Connection varchar(256) not null
	,@Referer varchar(256) not null
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
with native_compilation, schemabinding, execute as owner
as
begin atomic with 
(
	transaction isolation level = snapshot
	,language = N'English'
)
	declare
		@RequestId int

	insert into dbo.WebRequests_Memory
		(URL,RequestType,ClientIP,BytesReceived)
	values
		(@URL,@RequestType,@ClientIP,@BytesReceived);

	select @RequestId = SCOPE_IDENTITY();

	insert into dbo.WebRequestHeaders_Memory
		(RequestId,HeaderName,HeaderValue)
	values
		(@RequestId,'AUTHORIZATION',@Authorization);

	insert into dbo.WebRequestHeaders_Memory
		(RequestId,HeaderName,HeaderValue)
	values
		(@RequestId,'USERAGENT',@UserAgent);

	insert into dbo.WebRequestHeaders_Memory
		(RequestId,HeaderName,HeaderValue)
	values
		(@RequestId,'HOST',@Host);

	insert into dbo.WebRequestHeaders_Memory
		(RequestId,HeaderName,HeaderValue)
	values
		(@RequestId,'CONNECTION',@Connection);

	insert into dbo.WebRequestHeaders_Memory
		(RequestId,HeaderName,HeaderValue)
	values
		(@RequestId,'REFERER',@Referer);
	
	if @Param1 collate Latin1_General_100_BIN2 is not null and 
		@Param1Value collate Latin1_General_100_BIN2 is not null
	begin
		insert into dbo.WebRequestParams_Memory
			(RequestID,ParamName,ParamValue)						
		values
			(@RequestId,@Param1,@Param1Value);

		if @Param2 collate Latin1_General_100_BIN2 is not null and 
			@Param2Value collate Latin1_General_100_BIN2 is not null
		begin
			insert into dbo.WebRequestParams_Memory
				(RequestID,ParamName,ParamValue)						
			values
				(@RequestId,@Param2,@Param2Value);

			if @Param3 collate Latin1_General_100_BIN2 is not null and 
				@Param3Value collate Latin1_General_100_BIN2 is not null
			begin
				insert into dbo.WebRequestParams_Memory
					(RequestID,ParamName,ParamValue)						
				values
					(@RequestId,@Param3,@Param3Value);

				if @Param4 collate Latin1_General_100_BIN2 is not null and 
					@Param4Value collate Latin1_General_100_BIN2 is not null
				begin
					insert into dbo.WebRequestParams_Memory
						(RequestID,ParamName,ParamValue)						
					values
						(@RequestId,@Param4,@Param4Value);

					if @Param5 collate Latin1_General_100_BIN2 is not null and 
						@Param5Value collate Latin1_General_100_BIN2 is not null
						insert into dbo.WebRequestParams_Memory
							(RequestID,ParamName,ParamValue)						
						values
							(@RequestId,@Param5,@Param5Value);
				end
			end
		end
	end
end
go
