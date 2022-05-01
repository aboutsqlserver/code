/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*              Chapter 34. Introduction to Columnstore Indexes             */
/*     Switching Partition to a Table with Nonclustered Columnstore Index   */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 11 
begin
	raiserror('You should have SQL Server 2012+ to execute this script',16,1) with nowait
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'FactTable' and s.name = 'dbo'
)
	drop table dbo.FactTable
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'StagingTable' and s.name = 'dbo'
)
	drop table dbo.StagingTable
go

if exists(
	select *
	from sys.partition_schemes 
	where name = 'psFacts'
)
	drop partition scheme psFacts
go


if exists(
	select *
	from sys.partition_functions
	where name = 'pfFacts'
)
	drop partition function pfFacts
go


create partition function pfFacts(int)
as range left for values (1,2,3,4,5);
go

create partition scheme psFacts 
as partition pfFacts
all to ([FG2014]);
go

create table dbo.FactTable
(
	DateId int not null,
	ArticleId int not null,
	OrderId int not null,
	Quantity decimal(9,3) not null,
	UnitPrice money not null,
	Amount money not null,

	constraint PK_FactTable
	primary key clustered(DateId, ArticleId, OrderId)
	on psFacts(DateId)
)
go


;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N2 as T2) -- 1,024 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N5)
insert into dbo.FactTable(DateId, ArticleId, OrderId, Quantity, UnitPrice, Amount)
	select ID % 4 + 1, ID % 100, ID, ID % 10 + 1, ID % 15 + 1 , ID % 25 + 1
	from IDs;

create nonclustered columnstore index IDX_FactTable_Columnstore
on dbo.FactTable(DateId, ArticleId, OrderId, Quantity, UnitPrice, Amount)
on psFacts(DateId)
go

create table dbo.StagingTable
(
	DateId int not null,
	ArticleId int not null,
	OrderId int not null,
	Quantity decimal(9,3) not null,
	UnitPrice money not null,
	Amount money not null,

	constraint PK_StagingTable
	primary key clustered(DateId, ArticleId, OrderId)
	on [FG2014],

	constraint CHK_StagingTable
	check(DateId = 5)
)
go


/*** Step 1: Importing Data into Staging Table ***/

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N2 as T2) -- 1,024 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N5)
insert into dbo.StagingTable(DateId, ArticleId, OrderId, Quantity, UnitPrice, Amount)
	select 5, ID % 100, ID, ID % 10 + 1, ID % 15 + 1 , ID % 25 + 1
	from IDs;
go


/*** Step 2: Creating nonclustered columstore index ***/
create nonclustered columnstore index IDX_StagingTable_Columnstore
on dbo.StagingTable(DateId, ArticleId, OrderId, Quantity, UnitPrice, Amount)
on [FG2014]
go

/*** Step 3: Switching Partition ***/
alter table dbo.StagingTable
switch to dbo.FactTable
partition 5
go


-- Testing 
select DateId, count(*) 
from dbo.FactTable 
group by DateId
