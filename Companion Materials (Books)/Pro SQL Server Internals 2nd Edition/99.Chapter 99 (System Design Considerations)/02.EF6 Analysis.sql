/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*           Written by Dmitri V. Korotkevitch and Maxim Alexeyev           */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/*                http://discoveringdotnet.alexeyev.org                     */
/****************************************************************************/
/*                Chapter 16. System Design Considerations                  */
/*               Creating Database Objects for EF6 analysis                 */
/****************************************************************************/

use [SqlServerInternals]
go

if not exists (select * from sys.schemas where name = 'EF6')
	exec sp_executesql N'create schema [EF6]';
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'OrderItems' and s.name = 'ef6'
)
	drop table ef6.OrderItems;
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'Orders' and s.name = 'ef6'
)
	drop table ef6.Orders;
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'Customers' and s.name = 'ef6'
)
	drop table ef6.Customers;
go


create table ef6.Customers
(
	CustomerId int not null identity(1,1),
	FirstName nvarchar(255) null,
	LastName nvarchar(255) null,
	Email varchar(254) null,
	Modified datetime not null,
	Created datetime not null,
	LastPurchaseDate datetime null,
	CreditLimit int null,
	Photo varbinary(max) null,
	Ver timestamp not null,
	
	constraint PK_Customers 
	primary key clustered(CustomerId)
);

create table ef6.Orders
(
	OrderId int not null identity(1,1),
	CustomerId int not null,
	OrderNo varchar(32) not null,
	Modified datetime not null,
	Created datetime not null,

	constraint PK_Orders 
	primary key clustered(OrderId),

	constraint FK_Orders_Customers
	foreign key(CustomerId)
	references ef6.Customers(CustomerId)
);

create index IDX_Orders_Customers on ef6.Orders(CustomerId);

create table ef6.OrderItems
(
	OrderId int not null,
	OrderItemId int not null identity(1,1),
	Qty float not null,
	Price money not null,
 
	constraint PK_OrderItems 
	primary key clustered(OrderId, OrderItemID),

	constraint FK_OrderItems_Orders
	foreign key(OrderId)
	references ef6.Orders(OrderId)
);
