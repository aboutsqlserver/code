/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 13: Utilizing In-Memory OLTP                     */
/*                 01.Example of Vertical Partitioning                      */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop view if exists dbo.Products; 
drop table if exists dbo.ProductsInMem; 
drop table if exists dbo.ProductDescriptions;
go

/*
create table dbo.Products
(
	ProductId int not null identity(1,1),
    ProductName nvarchar(64) not null,
    ShortDescription nvarchar(256) not null,
    Description nvarchar(max) not null,

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
    ProductName nvarchar(64) not null,
    ShortDescription nvarchar(256) not null,

    index IDX_ProductsInMem_ProductName nonclustered(ProductName)
)
with (memory_optimized = on, durability = schema_and_data);

create table dbo.ProductDescriptions
(
    ProductId int not null,
    Description nvarchar(max) not null,
	
    constraint PK_ProductDescriptions
    primary key clustered(ProductId)
);
go

create view dbo.Products(ProductId, ProductName, 
    ShortDescription, Description)
as
    select 
        p.ProductId, p.ProductName, p.ShortDescription
        ,pd.Description
    from 
        dbo.ProductsInMem p left outer join 
            dbo.ProductDescriptions pd on
                p.ProductId = pd.ProductId;
go

select ProductId, ProductName
from dbo.Products;

