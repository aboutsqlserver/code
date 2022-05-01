/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
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

use InMemoryOLTP2016
go


/****************************************************************************/
/*         Scripts in this chapter prepare the database schema for          */
/*                   LogRequestsGenerator demo app                          */
/****************************************************************************/

drop proc if exists dbo.InsertRequestInfo_Memory;
drop proc if exists dbo.InsertRequestInfo_NativelyCompiled;
drop table if exists dbo.WebRequestHeaders_Memory;
drop table if exists dbo.WebRequestParams_Memory;
drop table if exists dbo.WebRequests_Memory;
go

create table dbo.WebRequests_Memory
(
	RequestId int not null identity(1,1)
		primary key nonclustered 
		hash with (bucket_count=1048576),
	RequestTime datetime2(4) not null
		constraint DEF_WebRequests_Memory_RequestTime
		default sysutcdatetime(),
	URL varchar(255) not null,
	RequestType tinyint not null, -- GET/POST/PUT
	ClientIP varchar(15) not null,
	BytesReceived int not null,
	
	index IDX_RequestTime nonclustered(RequestTime)
) 
with (memory_optimized=on, durability=schema_and_data)
go

create table dbo.WebRequestHeaders_Memory
(
	RequestHeaderId int not null identity(1,1)
		primary key nonclustered 
		hash with (bucket_count=8388608),
	RequestId int not null,
	HeaderName varchar(64) not null,
	HeaderValue varchar(256) not null,
	
	index IDX_RequestId nonclustered hash(RequestId)
	with (bucket_count=1048576),

	constraint FK_WebRequestHeaders_Memory_WebRequests_Memory
	foreign key(RequestId)
	references dbo.WebRequests_Memory(RequestId)
) 
with (memory_optimized=on, durability=schema_and_data)
go

create table dbo.WebRequestParams_Memory
(
	RequestParamId int not null identity(1,1)
		primary key nonclustered 
		hash with (bucket_count=8388608),
	RequestId int not null,
	ParamName varchar(64) not null,
	ParamValue nvarchar(256) not null,
	
	index IDX_RequestId nonclustered hash(RequestId)
	with (bucket_count=1048576),

	constraint FK_WebRequestParams_Memory_WebRequests_Memory
	foreign key(RequestId)
	references dbo.WebRequests_Memory(RequestId)
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
				(RequestId,ParamName,ParamValue)						
			select @RequestId, ParamName, ParamValue
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
		select @RequestId,'AUTHORIZATION',@Authorization union all 
		select @RequestId,'USERAGENT',@UserAgent union all
		select @RequestId,'HOST',@Host union all
		select @RequestId,'CONNECTION',@Connection union all
		select @RequestId,'REFERER',@Referer;

	insert into dbo.WebRequestParams_Memory(RequestId,ParamName,ParamValue)						
		select @RequestId, ParamName, ParamValue
		from 
		(
			select @Param1, @Param1Value union all
			select @Param2, @Param2Value union all
			select @Param3, @Param3Value union all
			select @Param4, @Param4Value union all
			select @Param5, @Param5Value 
		) v(ParamName, ParamValue)
		where
			ParamName is not null and
			ParamValue is not null;
end
go

