/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                 Chapter 33. In-Memory OLTP Programmability               */
/*                        Atomic Blocks (Session 1)		                    */
/****************************************************************************/

set noexec off
go

set nocount on
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 12 
begin
	raiserror('You should have SQL Server 2014 to execute this script',16,1) with nowait
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3 or charindex('X64',@@Version) = 0
begin
	raiserror('That script requires 64-Bit Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

if not exists (select * from sys.databases where name = 'SQLServerInternalsHK')
begin
	raiserror('Create [SQLServerInternalsHK] database with "03.Create Hekaton DB.sql" script from "00.Init" project',16,1)
	set noexec on
end
go

use SQLServerInternalsHK
go

if exists(
	select * 
	from sys.procedures p join sys.schemas s on 
		p.schema_id = s.schema_id
	where 
		p.name = 'AtomicBlockDemo' and s.name = 'dbo' 
)
	drop proc dbo.AtomicBlockDemo
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on 
		t.schema_id = s.schema_id 
	where s.name = 'dbo' and t.name = 'MOData'
)
	drop table dbo.MOData
go

create table dbo.MOData
(
	ID int not null
		primary key nonclustered
		hash with (bucket_count=10),
	Value int null
)
with (memory_optimized=on, durability=schema_only);

insert into dbo.MOData(ID, Value) 
values	
	(1,1), (2,2)
go

create proc dbo.AtomicBlockDemo
(
	@ID1 int not null
	,@Value1 bigint not null
	,@ID2 int 
	,@Value2 bigint 
)
with native_compilation, schemabinding, execute as owner
as
begin atomic
with (transaction isolation level = snapshot, language=N'us_english')
	update dbo.MOData set Value = @Value1 where ID = @ID1
	if @ID2 is not null
		update dbo.MOData set Value = @Value2 where ID = @ID2
end
go

/*** Non-Critical Errors ***/
-- Step 1
begin tran
	exec dbo.AtomicBlockDemo 1, -1, 2, -2
	exec dbo.AtomicBlockDemo 1, 0, 2, 999999999999999

	-- Step 2
	select @@TRANCOUNT as [@@TRANCOUNT], XACT_STATE() as [XACT_STATE()]
commit
select * from dbo.MOData
go


/*** Critical Errors ***/
-- Step 1
begin tran
	exec dbo.AtomicBlockDemo 1, 0, null, null

	/*** Run Session 2 code to trigger write/write conflict ***/
	-- Step 2
	select @@TRANCOUNT as [@@TRANCOUNT], XACT_STATE() as [XACT_STATE()]
commit
select * from dbo.MOData
go

