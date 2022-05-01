/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 10. Views                              */
/*                             Indexed Views                                */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'OrderLineItems') drop view dbo.OrderLineItems;
if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'vProductSaleStats') drop view dbo.vProductSaleStats;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'OrderLineItems') drop table dbo.OrderLineItems;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Products') drop table dbo.Products;
go

create table dbo.Products
(
	ProductID int not null identity(1,1),
	Name nvarchar(100) not null,

	constraint PK_Product
	primary key clustered(ProductID)
);

create table dbo.OrderLineItems
(
	OrderId int not null,
	OrderLineItemId int not null identity(1,1),
	Quantity decimal(9,3) not null, 
	Price smallmoney not null,
	ProductId int not null,
		
	constraint PK_OrderLineItems
	primary key clustered(OrderId,OrderLineItemId),

	constraint FK_OrderLineItems_Products
	foreign key(ProductId)
	references dbo.Products(ProductId)
);

create index IDX_OrderLineItems_ProductId 
on dbo.OrderLineItems(ProductId);
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2 ) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N5)
insert into dbo.Products(Name)
	select 'Product # ' + convert(varchar(5), ID)
	from IDs
	where ID <= 1000;

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2 ) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N5)
insert into dbo.OrderLineItems(OrderId,Quantity,Price,ProductId)
	select ID % 10, ID % 10, ID % 1000,	ID % 1000 + 1
	from Ids;
go

-- Enable "Include Actual Execution Plan"

set statistics io on

select top 10 p.ProductId, p.name as ProductName, sum(o.Quantity) as TotalQuantity
from dbo.OrderLineItems o join dbo.Products p on
	o.ProductId = p.ProductId
group by
	p.ProductId, p.Name  
order by
	TotalQuantity desc;

set statistics io off
go

create view dbo.vProductSaleStats(ProductId, ProductName, TotalQuantity, Cnt)
with schemabinding
as
	select p.ProductId, p.Name, sum(o.Quantity), count_big(*)
	from dbo.OrderLineItems o join dbo.Products p on
		o.ProductId = p.ProductId
	group by
		p.ProductId, p.Name ; 
go

create unique clustered index IDX_vProductSaleStats_ProductId
on dbo.vProductSaleStats(ProductId);

create nonclustered index IDX_vClientOrderTotal_TotalQuantity
on dbo.vProductSaleStats(TotalQuantity desc)
include(ProductName);
go


set statistics io on

select top 10 ProductId, ProductName, TotalQuantity   
from dbo.vProductSaleStats
order by TotalQuantity desc;

set statistics io off
go

-- Indexed views can be used even when it is not referenced in Enterprise Edition
select top 10 p.ProductId, p.name as ProductName, sum(o.Quantity) as TotalQuantity
from dbo.OrderLineItems o join dbo.Products p on
	o.ProductId = p.ProductId
group by
	p.ProductId, p.Name  
order by
	TotalQuantity desc;

select p.ProductId, p.Name
from dbo.Products p
where 
	exists
	(
		select *
		from dbo.OrderLineItems o 
		where p.ProductId = o.ProductId 
	);
go

-- Update overhead
insert into dbo.OrderLineItems(OrderId,Quantity,Price,ProductId)
values(42,42,42,42);
go



