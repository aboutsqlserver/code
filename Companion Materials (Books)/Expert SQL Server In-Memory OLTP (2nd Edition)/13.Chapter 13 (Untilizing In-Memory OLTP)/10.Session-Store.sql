/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 13: Utilizing In-Memory OLTP                     */
/*     10.Using In-Memory OLTP as the Session- or Object-State Store        */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go


/****************************************************************************/
/*  This script prepares the database schema for ObjStoreDemo demo app  */
/****************************************************************************/

drop proc if exists dbo.LoadObjectFromStore_Disk; 
drop proc if exists dbo.LoadObjectFromStore; 
drop proc if exists dbo.SaveObjectToStore; 
drop proc if exists dbo.SaveObjectToStore_Disk; 
drop table if exists dbo.ObjStore; 
drop table if exists dbo.ObjStore_Disk; 
go

create table dbo.ObjStore
(
	ObjectKey uniqueidentifier not null,
	ExpirationTime datetime2(2) not null,
	Data varbinary(max) not null,
	 
	constraint PK_ObjStore 
	primary key nonclustered hash (ObjectKey)
	with (bucket_count=1048576),
)
with (memory_optimized = on, durability = schema_only);
go 

create proc dbo.SaveObjectToStore
(
	@ObjectKey uniqueidentifier
	,@ExpirationTime datetime2(2)
	,@Data varbinary(max) 
)
with native_compilation, schemabinding, exec as owner
as
begin atomic with
(
	transaction isolation level = snapshot
	,language = N'English'
)
	-- @ObjectKeys are randomly generated and unique across
	-- multiple sessions
	update dbo.ObjStore
	set Data = @Data, ExpirationTime = @ExpirationTime
	where ObjectKey = @ObjectKey;
	
	if (@@rowcount = 0)
		insert into dbo.ObjStore(ObjectKey, ExpirationTime, Data)
		values(@ObjectKey, @ExpirationTime, @Data)
end
go

create proc dbo.LoadObjectFromStore
(
	@ObjectKey uniqueidentifier not null
	,@Data varbinary(max) output
)
with native_compilation, schemabinding, exec as owner
as
begin atomic
with
(
	transaction isolation level = snapshot
	,language = N'English'
)
	select @Data = t.Data
	from dbo.ObjStore t
	where t.ObjectKey = @ObjectKey and 
		ExpirationTime >= sysutcdatetime();
end
go

create table dbo.ObjStore_Disk
(
	ObjectKey uniqueidentifier not null,
	ExpirationTime datetime2(2) not null,
	Data varbinary(max) not null,
	 
	constraint PK_ObjStore_Disk 
	primary key clustered(ObjectKey)
)
go 

create proc dbo.SaveObjectToStore_Disk
(
	@ObjectKey uniqueidentifier
	,@ExpirationTime datetime2(2)
	,@Data varbinary(max) 
)
as
begin 
	set nocount on
	set xact_abort on

	;merge into dbo.ObjStore_Disk as T
	using 
	(
		select 
			@ObjectKey as ObjectKey
			,@ExpirationTime as ExpirationTime
			,@Data as Data
	) as S
	on T.ObjectKey = S.ObjectKey
	when matched then
		update set T.Data = S.Data, T.ExpirationTime = @ExpirationTime
	when not matched by target then
		insert (ObjectKey, ExpirationTime, Data)
		values(S.ObjectKey, S.ExpirationTime, S.Data);
end
go

create proc dbo.LoadObjectFromStore_Disk
(
	@ObjectKey uniqueidentifier
	,@Data varbinary(max) output
)
as
	select @Data = t.Data
	from dbo.ObjStore_Disk t
	where t.ObjectKey = @ObjectKey and 
		ExpirationTime >= sysutcdatetime();
go