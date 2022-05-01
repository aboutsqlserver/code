/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*          Chapter 33. Column-Based Storage and Batch Mode Execution       */
/*                          Batch Mode Execution                            */
/****************************************************************************/

set noexec off
go

set nocount on
go

/****************************************************************************/
/* This script takes several minutes to execute and will generate large     */
/* (several GBs) data and log files                                         */
/****************************************************************************/

use [SqlServerInternals]
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 11 
begin
	raiserror('You should have SQL Server 2012+ to execute this script',16,1) with nowait;
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'FactSales') drop table dbo.FactSales;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'DimDates') drop table dbo.DimDates;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'DimArticles') drop table dbo.DimArticles;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'DimBranches') drop table dbo.DimBranches;
go

create table dbo.DimBranches
(
	BranchId int not null primary key,
	BranchNumber nvarchar(32) not null,
	BranchCity nvarchar(32) not null, 
	BranchRegion nvarchar(32) not null, 
	BranchCountry nvarchar(32) not null
);

create table dbo.DimArticles
(
	ArticleId int not null primary key,
	ArticleCode nvarchar(32) not null,
	ArticleCategory nvarchar(32) not null
);

create table dbo.DimDates
(
	DateId int not null primary key, 
	ADate date not null,
	ADay tinyint not null,
	AMonth tinyint not null, 
	AnYear smallint not null, 
	AQuarter tinyint not null, 
	ADayOfWeek tinyint not null
);

create table dbo.FactSales
(
	DateId int not null
		foreign key references dbo.DimDates(DateId),
	ArticleId int not null
		foreign key references dbo.DimArticles(ArticleId),
	BranchId int not null
		foreign key references dbo.DimBranches(BranchId),
	OrderId int not null,
	Quantity decimal(9,3) not null, 
	UnitPrice money not null,
	Amount money not null,
	DiscountPcnt decimal (6,3) not null,
	DiscountAmt money not null,
	TaxAmt  money not null,
	primary key (DateId, ArticleId, BranchId, OrderId)
	with (data_compression = page)
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N2 as T1 cross join N4 as T2) -- 1,024 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N5)
,Dates(DateId, ADate) 
as
(
	select ID, dateadd(day,ID,'2014-12-31')
	from IDs
	where ID <= 727
)
insert into dbo.DimDates(DateId, ADate, ADay, AMonth, AnYear
	,AQuarter, ADayOfWeek)
	select DateID, ADate, Day(ADate), Month(ADate), Year(ADate)
		,datepart(qq,ADate), datepart(dw,ADate)
	from Dates;

      
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N3)
insert into dbo.DimBranches(BranchId, BranchNumber, BranchCity, 
		BranchRegion, BranchCountry)
	select ID, convert(nvarchar(32),ID), 'City', 'Region', 'Country'
	from IDs
	where ID <= 13;

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N2 as T2) -- 1,024 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N5)
insert into dbo.DimArticles(ArticleId, ArticleCode, ArticleCategory)
	select ID, convert(nvarchar(32),ID), 'Category ' + convert(nvarchar(32),ID % 51)
	from IDs
	where ID <= 1021;

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,N6(C) as (select 0 from N5 as T1 cross join N4 as T2) -- 16,777,216 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N6)
insert into dbo.FactSales(DateId, ArticleId, BranchId, OrderId
		, Quantity, UnitPrice, Amount, DiscountPcnt, DiscountAmt, TaxAmt)
		select ID % 727 + 1, ID % 1021 + 1, ID % 13 + 1, ID
			,ID % 51 + 1, ID % 25 + 0.99
			,(ID % 51 + 1) * (ID % 25 + 0.99), 0, 0
			,(ID % 25 + 0.99) * (ID % 10) * 0.01
		from IDs;

create nonclustered columnstore index IDX_FactSales_ColumnStore
on dbo.FactSales(DateId, ArticleId, BranchId, Quantity, UnitPrice, Amount);
go

/*** Test Queries ***/

-- You will get different execution plans in different versions of SQL Server.
-- In SQL Server 2016, you can also get different plans based on database compatibility levels.  
set statistics time, io on

-- Forcing Row-Mode Execution with Clustered Index Scan
select a.ArticleCode, SUM(s.Amount) as [TotalAmount]
from dbo.FactSales s with (index = 1) join dbo.DimArticles a on
	s.ArticleId = a.ArticleId
group by
	a.ArticleCode
-- option (maxdop 1)

-- Forcing Batch-Mode Execution with Clustered Index Scan (Requires MAXDOP > 1)
select a.ArticleCode, SUM(s.Amount) as [TotalAmount]
from dbo.FactSales s join dbo.DimArticles a on
	s.ArticleId = a.ArticleId
group by
	a.ArticleCode
-- option (maxdop 1)

set statistics time, io off
go

-- Key Lookup Operation
select OrderId, Amount, TaxAmt
from dbo.FactSales
where ArticleId = 10;
go