/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                             Chapter 12. XML                              */
/*                              SELECT FOR XML                              */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

declare
    @Orders table
    (
        OrderId int not null primary key,
        CustomerId int not null,
        OrderNum varchar(32) not null,
        OrderDate datetime not null
    )
declare
    @OrderLineItems table
    (
        OrderId int not null,
        ArticleId int not null,
        Quantity int not null,
        Price money not null,
        primary key(OrderId, ArticleId)
    )

insert into @Orders(OrderId, CustomerId, OrderNum, OrderDate) values(42,123,'10025','2016-07-15T10:05:20');
insert into @Orders(OrderId, CustomerId, OrderNum, OrderDate) values(54,25,'10032','2016-07-15T11:21:00');

insert into @OrderLineItems(OrderId, ArticleId, Quantity, Price) values(42,250,3,9.99);
insert into @OrderLineItems(OrderId, ArticleId, Quantity, Price) values(42,404,1,19.99);
insert into @OrderLineItems(OrderId, ArticleId, Quantity, Price) values(54,15,1,14.99);
insert into @OrderLineItems(OrderId, ArticleId, Quantity, Price) values(54,121,2,6.99);

select
    o.OrderId as [@OrderId]
    ,o.OrderNum as [OrderNum]
    ,o.CustomerId as [CustomerId] 
    ,o.OrderDate as [OrderDate] 
    ,( select   
            i.ArticleId as [@ArticleId]
            ,i.Quantity as [@Quantity]
            ,i.Price as [@Price]
        from @OrderLineItems i
        where i.OrderId = o.OrderId
        for xml path('OrderLineItem'),root('OrderLineItems'), type )
from @Orders o
for xml path('Order'),root('Orders');

-- Creating Comma-Separated List of characters
select left(Data,len(Data) - 1) -- removing right-most comma 
from
    ( select convert(varchar(max),  
        ( select OrderId as [text()], ',' as [text()]
          from @Orders
          for xml path('') ) ) as Data
    ) List;


