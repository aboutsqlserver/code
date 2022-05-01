/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*    08.Memory-Optimized Table Variable Performance (DW) - Create Tables   */
/****************************************************************************/

set noexec off
go

set nocount on
go

use InMemoryOLTP2014
go

if not exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'InputData')
begin
	raiserror('Create dbo.InputData table using scripts/data from ETL subfolder',16,1);
	set noexec on
end
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dw' and t.name = 'FactSales') drop table dw.FactSales; 
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dw' and t.name = 'DimDates') drop table dw.DimDates;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dw' and t.name = 'DimProducts') drop table dw.DimProducts; 
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dw' and t.name = 'FactSalesETLDisk') drop table dw.FactSalesETLDisk;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dw' and t.name = 'FactSalesETLMem') drop table dw.FactSalesETLMem; 
go

if not exists(select * from sys.schemas where name = 'dw')
	exec sp_executesql N'create schema dw authorization dbo'
go

create table dw.DimDates
(
	ADateId int identity(1,1) not null,
	ADate date not null,
	ADay tinyint not null,
	AMonth tinyint not null,
	AnYear smallint not null,
	ADayOfWeek tinyint not null,

	constraint PK_DimDates
	primary key clustered(ADateId)
);

declare
	@MinDate date = '2013-01-01'

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N3 as t2) -- 4,096 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N5)
,Dates(ADate) as ( select dateadd(day,Id,@MinDate) from Ids)
insert into dw.DimDates(ADate,ADay,AMonth,AnYear,ADayOfWeek)
	select ADate,day(ADate),month(ADate),year(ADate),datepart(dw,ADate)
	from Dates
go


create unique nonclustered index IDX_DimDates_ADate
on dw.DimDates(ADate);

create table dw.DimProducts
(
	ProductId int identity(1,1) not null,
	Product nvarchar(64) not null,
	ProductBin nvarchar(64)  
		collate Latin1_General_100_BIN2
		not null,

	constraint PK_DimProducts
	primary key clustered(ProductId)
);

insert into dw.DimProducts(Product,ProductBin)
	select distinct Product, Product
	from dbo.InputData;

create unique nonclustered index IDX_DimProducts_Product
on dw.DimProducts(Product);

create unique nonclustered index IDX_DimProducts_ProductBin
on dw.DimProducts(ProductBin);

create table dw.FactSales
(
	ADateId int not null,
	ProductId int not null,
	OrderId int not null,
	OrderNum varchar(32) not null,
	Quantity decimal(9,3) not null,
	UnitPrice money not null,
	Amount money not null,

	constraint PK_FactSales
	primary key (ADateId,ProductId,OrderId),

	constraint FK_FactSales_DimDates
	foreign key(ADateId)
	references dw.DimDates(ADateId),

	constraint FK_FactSales_DimProducts
	foreign key(ProductId)
	references dw.DimProducts(ProductId)
);


create table dw.FactSalesETLDisk
(
	OrderId int not null,
	OrderNum varchar(32) not null,
	Product nvarchar(64) not null,
	ADate date not null,
	Quantity decimal(9,3) not null,
	UnitPrice money not null,
	Amount money not null,
	/* Optional Placeholder Column */
	--Placeholder char(255) null,
	primary key (OrderId, Product)
)
go

create table dw.FactSalesETLMem
(
	OrderId int not null,
	OrderNum varchar(32) not null,
	Product nvarchar(64)
		collate Latin1_General_100_BIN2 not null,
	ADate date not null,
	Quantity decimal(9,3) not null,
	UnitPrice money not null,
	Amount money not null,
	/* Optional Placeholder Column */
	--Placeholder char(255) null,

	constraint PK_FactSalesETLMem
	primary key nonclustered hash(OrderId, Product)
	with (bucket_count = 2000000)

	/* Optional Index */
	--,index IDX_Product nonclustered(Product)
)
with (memory_optimized=on, durability=schema_and_data)
go

