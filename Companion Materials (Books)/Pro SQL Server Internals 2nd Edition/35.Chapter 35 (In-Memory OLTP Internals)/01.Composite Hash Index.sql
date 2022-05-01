/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                  Chapter 35. In-Memory OLTP Internals                    */
/*                          Composite Hash Index                            */
/****************************************************************************/

set noexec off
go

if convert(int,
		left(
			convert(nvarchar(128), serverproperty('ProductVersion')),
			charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
		)
) < 12 
begin
	raiserror('You should have SQL Server 2014-2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3 or charindex('X64',@@Version) = 0
begin
	raiserror('That script requires 64-Bit Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

if not exists (select * from sys.databases where name = 'SQLServerInternalsHK')
begin
	raiserror('Create [SQLServerInternalsHK] database with "02.Create In-Memory OLTP DB.sql" script from "00.Init" project',16,1);
	set noexec on
end
go

use SQLServerInternalsHK
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'CustomersOnDisk') drop table dbo.CustomersOnDisk;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'CustomersMemoryOptimized') drop table dbo.CustomersMemoryOptimized;
go

/* You do not need to use BIN2 collations with SQL Server 2016 */
create table dbo.CustomersOnDisk
(
	CustomerId int not null identity(1,1),
	FirstName varchar(64) collate Latin1_General_100_BIN2 not null,
	LastName varchar(64) collate Latin1_General_100_BIN2 not null,
	Placeholder char(100) null,

	constraint PK_CustomersOnDisk
	primary key clustered(CustomerId)
);

create nonclustered index IDX_CustomersOnDisk_LastName_FirstName
on dbo.CustomersOnDisk(LastName, FirstName);
go

create table dbo.CustomersMemoryOptimized
(
	CustomerId int not null identity(1,1)
		constraint PK_CustomersMemoryOptimized
		primary key nonclustered 
		hash with (bucket_count = 30000),
	FirstName varchar(64) collate Latin1_General_100_BIN2 not null,
	LastName varchar(64) collate Latin1_General_100_BIN2 not null,
	Placeholder char(100) null,

	index IDX_CustomersMemoryOptimized_LastName_FirstName
	nonclustered hash(LastName, FirstName)
	with (bucket_count = 1024),
)
with (memory_optimized = on, durability = schema_only)
go

-- Inserting cross-joined data for all first and last names 50 times 
-- using GO 50 command in Management Studio
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N2 as T2) -- 64 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select null)) from N4)
,FirstNames(FirstName)
as
(
	select Names.Name
	from 
	(
		values('Andrew'),('Andy'),('Anton'),('Ashley'),('Boris'),
		('Brian'),('Cristopher'),('Cathy'),('Daniel'),('Donny'),
		('Edward'),('Eddy'),('Emy'),('Frank'),('George'),('Harry'),
		('Henry'),('Ida'),('John'),('Jimmy'),('Jenny'),('Jack'),
		('Kathy'),('Kim'),('Larry'),('Mary'),('Max'),('Nancy'),
		('Olivia'),('Paul'),('Peter'),('Patrick'),('Robert'),
		('Ron'),('Steve'),('Shawn'),('Tom'),('Timothy'),
		('Uri'),('Vincent')
	) Names(Name)
)
,LastNames(LastName)
as
(
	select Names.Name
	from 
	(
		values('Smith'),('Johnson'),('Williams'),('Jones'),('Brown'),
			('Davis'),('Miller'),('Wilson'),('Moore'),('Taylor'),
			('Anderson'),('Jackson'),('White'),('Harris')
	) Names(Name)
)
insert into dbo.CustomersOnDisk(LastName, FirstName)
	select LastName, FirstName
	from FirstNames cross join LastNames cross join IDs;
go 

insert into dbo.CustomersMemoryOptimized(LastName, FirstName)
	select LastName, FirstName
	from dbo.CustomersOnDisk;
go

-- Enable "Include Actual Execution Plan"
select CustomerId, FirstName, LastName
from dbo.CustomersOnDisk
where FirstName = 'Paul' and LastName = 'White';

select CustomerId, FirstName, LastName
from dbo.CustomersMemoryOptimized
where FirstName = 'Paul' and LastName = 'White';
go

select CustomerId, FirstName, LastName
from dbo.CustomersOnDisk
where LastName = 'White';

select CustomerId, FirstName, LastName
from dbo.CustomersMemoryOptimized
where LastName = 'White';
go



