/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*01.Example of Vertical Partitioning (Addressing 8,060-byte row size limit)*/
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertProduct' and s.name = 'dbo') drop proc dbo.InsertProduct;
if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'Products') drop view dbo.Products; 
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'ProductsInMem') drop table dbo.ProductsInMem; 
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'ProductAttributes') drop table dbo.ProductAttributes;
go

/*
create table dbo.Products
(
	ProductId int not null identity(1,1),
    ProductName nvarchar(64) not null,
    ShortDescription nvarchar(256) not null,
    Description nvarchar(max) not null,
    Picture varbinary(max) null,

    constraint PK_Products
    primary key clustered(ProductId)
)
*/

create table dbo.ProductsInMem
(
    ProductId int not null identity(1,1)
        constraint PK_ProductsInMem
        primary key nonclustered hash
        with (bucket_count = 65536),
    ProductName nvarchar(64) 
        collate Latin1_General_100_BIN2 not null,
    ShortDescription nvarchar(256) not null,

    index IDX_ProductsInMem_ProductName nonclustered(ProductName)
)
with (memory_optimized = on, durability = schema_and_data);

create table dbo.ProductAttributes
(
    ProductId int not null,
    Description nvarchar(max) not null,
    Picture varbinary(max) null,
	
    constraint PK_ProductAttributes
    primary key clustered(ProductId)
);
go

create view dbo.Products(ProductId, ProductName, 
    ShortDescription, Description, Picture)
as
    select 
        p.ProductId, p.ProductName, p.ShortDescription
        ,pa.Description, pa.Picture
    from 
        dbo.ProductsInMem p left outer join 
            dbo.ProductAttributes pa on
                p.ProductId = pa.ProductId;
go

select ProductId, ProductName
from dbo.Products;

