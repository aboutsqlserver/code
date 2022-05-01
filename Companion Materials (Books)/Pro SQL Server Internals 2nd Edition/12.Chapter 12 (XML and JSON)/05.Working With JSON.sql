/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                             Chapter 12. XML                              */
/*                         Working with JSON Data                           */
/****************************************************************************/
set noexec off
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 13
begin
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

use [SqlServerInternals]
go

-- SELECT FOR JSON
declare
	@Orders table
	(
		OrderId int not null primary key,
		CustomerId int not null,
		OrderNum varchar(32) not null,
		OrderDate date not null
	);

declare
	@OrderLineItems table
	(
		OrderId int not null,
		ArticleId int not null,
		Quantity int not null,
		Price money not null,
		primary key(OrderId, ArticleId)
	);

insert into @Orders(OrderId, CustomerId, OrderNum, OrderDate)
values
	(42,123,'10025','2016-07-15T10:05:20'),
	(54,25,'10032','2016-07-15T11:21:00');

insert into @OrderLineItems(OrderId, ArticleId, Quantity, Price)
values
	(42,250,3,9.99), (42,404,1,19.99),
	(54,15,1,14.99), (54,121,2,6.99);

select
    o.OrderId as [OrderId]
    ,o.OrderNum as [OrderNum]
    ,o.CustomerId as [CustomerId] 
    ,o.OrderDate as [OrderDate]
    ,(
        select
            i.ArticleId as [ArticleId]
            ,i.Quantity as [Quantity]
            ,i.Price as [Price]
        from @OrderLineItems i
        where i.OrderId = o.OrderId
        for json auto
    ) as LineItems
from @Orders o
for json auto;
go

-- JSON Functions
declare
    @Data nvarchar(max) = N'
{
    "Book":{
        "Title":"Pro SQL Server Internals 2nd Edition",
        "ISBN":"978-1484219638",
        "Author": {
            "Name":"Dmitri Korotkevitch",
            "Blog":"http://aboutsqlserver.com"
        }
    }
}';

select 
    isjson(@Data) as [Is JSON]
    ,json_value(@Data,'$.Book.Title') as [Title]
    ,json_query(@Data,'$.Book.Author') as [Author in JSON]
    ,json_modify(@Data,'$.Book.Year',2016) as [Modified JSON];
go

-- Open JSON: Requires DB Compatibility Level = 130
declare
	@Data varchar(max) = '[{"OrderId":42,"OrderNum":"10025","CustomerId":123,"OrderDate":"2016-07-15","LineItems":[{"ArticleId":250,"Quantity":3,"Price":9.9900},{"ArticleId":404,"Quantity":1,"Price":19.9900}]},{"OrderId":54,"OrderNum":"10032","CustomerId":25,"OrderDate":"2016-07-15","LineItems":[{"ArticleId":15,"Quantity":1,"Price":14.9900},{"ArticleId":121,"Quantity":2,"Price":6.9900}]}]'

select Orders.OrderId, Orders.CustomerId, Orders.OrderNum
	,Orders.OrderDate, Orders.LineItems, sum(Items.Quantity * Items.Price) as Total, '', '' 
from 
	openjson(@Data,'$') 
	with 
	(
		OrderId int '$.OrderId',
		CustomerId int '$.CustomerId',
		OrderNum varchar(32) '$.OrderNum',
		OrderDate date '$.OrderDate',
		LineItems nvarchar(max) '$.LineItems' as json
	) as Orders
	cross apply
		openjson(Orders.LineItems,'$')
		with 
		(
			Quantity int '$.Quantity',
			Price float '$.Price'
		) as Items
group by
	Orders.OrderId, Orders.CustomerId, Orders.OrderNum, Orders.OrderDate, Orders.LineItems;
