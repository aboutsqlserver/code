/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                   Chapter 32. In-Memory OLTP Internals                   */
/*              Concurrency Model: Write/Write Conflict (Session 1)         */
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

if exists
(
	select * 
	from sys.tables t join sys.schemas s on 
		t.schema_id = s.schema_id 
	where s.name = 'dbo' and t.name = 'HKData'
)
	drop table dbo.HKData
go

create table dbo.HKData
(
	ID int not null,
	Col int not null,
	
	constraint PK_HKData
	primary key nonclustered hash(ID) 
	with (bucket_count=64),
)
with (memory_optimized=on, durability=schema_only)  
go

insert into dbo.HKData(ID, Col) 
values(1,1),(2,2),(3,3),(4,4),(5,5);
go

/*** Test 1 ***/
-- Step 1
begin tran
	select ID, Col 
	from dbo.HKData with (Snapshot)

	/*** Run Session 2 code ***/

	-- Step 2
	update dbo.HKData with (snapshot)
	set Col = -2
	where ID = 2
commit
go

/*** Test 2 ***/
-- Step 1
begin tran
	select ID, Col 
	from dbo.HKData with (Snapshot)

	/*** Run Session 2 code ***/

	-- Step 2
	update dbo.HKData with (snapshot)
	set Col = -2
	where ID = 2
commit
go
