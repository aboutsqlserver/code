/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*            Appendix D: In-Memory OLTP Migration Tools                    */
/*                     01.Creating On-Disk Objects                          */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

/****************************************************************************/
/* Scripts in this chapter prepare the database schema for	                */   
/* LogRequestsGenerator demo app. It is similar to Chapter 02 with several  */
/* constructs incompatible with In-Memory OLTP                              */
/****************************************************************************/

drop proc if exists dbo.InsertRequestInfo_Disk;
drop table if exists dbo.WebRequestHeaders_Disk;
drop table if exists dbo.WebRequestParams_Disk;
drop table if exists dbo.WebRequests_Disk;
go

create table dbo.WebRequests_Disk
(
	RequestId int not null Identity(1,1),
	RequestTime datetime2(4) not null
		constraint DEF_WebRequests_Disk_RequestTime
		default sysutcdatetime(),
	URL varchar(255) not null,
	RequestType tinyint not null, -- GET/POST/PUT
	ClientIP varchar(15) not null,
	BytesReceived int not null,
	Attributes xml null,
	Location geography null,
	
	constraint PK_WebRequests_Disk
	primary key nonclustered(RequestId)
	on [LOGDATA]
) on [LOGDATA]
go

create unique clustered index IdX_WebRequests_Disk_RequestTime_RequestId
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
	primary key clustered(RequestId,HeaderName)
	on [LOGDATA]
) 
go

create table dbo.WebRequestParams_Disk
(
	RequestId int not null,
	ParamName varchar(64) not null,
	ParamValue nvarchar(256) not null,
	
	constraint PK_WebRequestParams_Disk
	primary key clustered(RequestId,ParamName)
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

		select @RequestId = SCOPE_IdENTITY();

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
		merge into dbo.WebRequestParams_Disk as T
		using 
		(
			select @RequestId as RequestId, ParamName, ParamValue
			from Params
		) as S
		on S.RequestId = T.RequestId
		when not matched by target then
			insert (RequestId,ParamName,ParamValue)						
			values(S.RequestId, S.ParamName, S.ParamValue);
	commit
end
go

