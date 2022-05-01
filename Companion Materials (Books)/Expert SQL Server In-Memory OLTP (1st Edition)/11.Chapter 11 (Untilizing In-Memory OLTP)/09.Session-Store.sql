/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*     09.Using In-Memory OLTP as the Session- or Object-State Store        */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go


/****************************************************************************/
/*  This script prepares the database schema for SessionStoreDemo demo app  */
/****************************************************************************/

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'LoadObjectFromStore_Disk') drop proc dbo.LoadObjectFromStore_Disk; 
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'LoadObjectFromStore') drop proc dbo.LoadObjectFromStore; 
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'SaveObjectToStore_Row') drop proc dbo.SaveObjectToStore_Row; 
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'SaveObjectToStore') drop proc dbo.SaveObjectToStore; 
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'SaveObjectToStore_Disk') drop proc dbo.SaveObjectToStore_Disk; 
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'SaveObjectToStore_Row_Disk') drop proc dbo.SaveObjectToStore_Row_Disk; 
if exists(select * from sys.types t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'tvpObjData') drop type dbo.tvpObjData; 
if exists(select * from sys.types t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'tvpObjData_Disk') drop type dbo.tvpObjData_Disk; 
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'SessionStore') drop table dbo.SessionStore; 
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'SessionStore_Disk') drop table dbo.SessionStore_Disk; 
go

create table dbo.SessionStore
(
	ObjectKey uniqueidentifier not null,
	ExpirationTime datetime2(2) not null,
	ChunkNum smallint not null,
	Data varbinary(8000) not null,
	 
	constraint PK_ObjStore 
	primary key nonclustered hash (ObjectKey, ChunkNum)
	with (bucket_count=1048576),

    index IDX_ObjectKey
    nonclustered hash(ObjectKey)
    with (bucket_count=1048576)
)
with (memory_optimized = on, durability = schema_only);
go 

create type dbo.tvpObjData as table
(
	ChunkNum smallint not null
		primary key nonclustered hash
		with (bucket_count = 128),
	Data varbinary(8000) not null
)
with(memory_optimized=on)
go 

create proc dbo.SaveObjectToStore
(
	@ObjectKey uniqueidentifier
	,@ExpirationTime datetime2(2)
	,@ObjData dbo.tvpObjData readonly 
)
with native_compilation, schemabinding, exec as owner
as
begin atomic with
(
	transaction isolation level = snapshot
	,language = N'English'
)
	delete dbo.SessionStore
	where ObjectKey = @ObjectKey

	insert into dbo.SessionStore(ObjectKey, ExpirationTime, ChunkNum, Data)
		select @ObjectKey, @ExpirationTime, ChunkNum, Data
	from @ObjData
end
go

create proc dbo.SaveObjectToStore_Row
(
	@ObjectKey uniqueidentifier
	,@ExpirationTime datetime2(2)
	,@ObjData varbinary(8000) 
)
with native_compilation, schemabinding, exec as owner
as
begin atomic with
(
	transaction isolation level = snapshot
	,language = N'English'
)
	delete dbo.SessionStore
	where ObjectKey = @ObjectKey

	insert into dbo.SessionStore(ObjectKey, ExpirationTime, ChunkNum, Data)
	values(@ObjectKey, @ExpirationTime, 1, @ObjData)
end
go

create proc dbo.LoadObjectFromStore
(
	@ObjectKey uniqueidentifier not null
)
with native_compilation, schemabinding, exec as owner
as
begin atomic
with
(
	transaction isolation level = snapshot
	,language = N'English'
)
	select t.Data
	from dbo.SessionStore t
	where t.ObjectKey = @ObjectKey and ExpirationTime >= sysutcdatetime()
	order by t.ChunkNum 
end
go



create table dbo.SessionStore_Disk
(
	ObjectKey uniqueidentifier not null,
	ExpirationTime datetime2(2) not null,
	ChunkNum smallint not null,
	Data varbinary(8000) not null,
	 
	constraint PK_ObjStore_Disk 
	primary key clustered(ObjectKey, ChunkNum)
)
go 

create type dbo.tvpObjData_Disk as table
(
	ChunkNum smallint not null primary key,
	Data varbinary(8000) not null
)
go 

create proc dbo.SaveObjectToStore_Disk
(
	@ObjectKey uniqueidentifier
	,@ExpirationTime datetime2(2)
	,@ObjData dbo.tvpObjData_Disk readonly 
)
as
begin 
	set nocount on
	set xact_abort on

	begin tran
		delete dbo.SessionStore_Disk
		where ObjectKey = @ObjectKey

		insert into dbo.SessionStore_Disk(ObjectKey, ExpirationTime, ChunkNum, Data)
			select @ObjectKey, @ExpirationTime, ChunkNum, Data
			from @ObjData
	commit
end
go

create proc dbo.SaveObjectToStore_Row_Disk
(
	@ObjectKey uniqueidentifier
	,@ExpirationTime datetime2(2)
	,@ObjData varbinary(8000) 
)
as
begin 
	set nocount on
	set xact_abort on

	begin tran
		delete dbo.SessionStore_Disk
		where ObjectKey = @ObjectKey

		insert into dbo.SessionStore_Disk(ObjectKey, ExpirationTime, ChunkNum, Data)
		values(@ObjectKey, @ExpirationTime, 1, @ObjData)
	commit
end
go

create proc dbo.LoadObjectFromStore_Disk
(
	@ObjectKey uniqueidentifier
)
as
	select t.Data
	from dbo.SessionStore_Disk t
	where t.ObjectKey = @ObjectKey and ExpirationTime >= sysutcdatetime()
	order by t.ChunkNum 
go