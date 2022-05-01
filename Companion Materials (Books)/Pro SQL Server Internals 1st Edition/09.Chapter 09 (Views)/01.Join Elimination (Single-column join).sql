/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                           Chapter 09. Views                              */
/*                  Join Elimination (Single-column joins)                  */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists
(
	select * 
	from sys.views v join sys.schemas s on
		v.schema_id = s.schema_id
	where
		s.name = 'dbo' and v.name = 'vOrders'    
)
	drop view dbo.vOrders
go

if exists
(
	select * 
	from sys.views v join sys.schemas s on
		v.schema_id = s.schema_id
	where
		s.name = 'dbo' and v.name = 'vOrders2'    
)
	drop view dbo.vOrders2
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'OrderItems'    
)
	drop table dbo.OrderItems
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Orders'    
)
	drop table dbo.Orders
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Clients'    
)
	drop table dbo.Clients
go

create table dbo.Clients
(
	ClientId int not null,
	ClientName varchar(32),
	
	constraint PK_Clients
	primary key clustered(ClientId)
);

create table dbo.Orders
(
	OrderId int not null identity(1,1),
	Clientid int not null,
	OrderDate datetime not null,
	OrderNumber varchar(32) not null,
	Amount smallmoney not null,

	constraint PK_Orders
	primary key clustered(OrderId)
)
go

create view dbo.vOrders(OrderId, Clientid, OrderDate, OrderNumber, Amount, ClientName)
as
	select o.OrderId, o.ClientId, o.OrderDate, o.OrderNumber, o.Amount, c.ClientName
	from
		dbo.Orders o join dbo.Clients c on
			o.Clientid = c.ClientId
go

-- Enable "Include Actual Execution Plan"

-- Everything is OK
select OrderId, Clientid, ClientName, OrderDate, OrderNumber, Amount
from dbo.vOrders 
where OrderId = 1

-- Unexpected join
select OrderId, OrderNumber, Amount
from dbo.vOrders 
where OrderId = 1
go

/*** Solution 1 - Outer join (changing view semantic) ***/
create view dbo.vOrders2(OrderId, Clientid, OrderDate, OrderNumber, Amount, ClientName)
as
	select o.OrderId, o.ClientId, o.OrderDate, o.OrderNumber, o.Amount, c.ClientName
	from
		dbo.Orders o left outer join dbo.Clients c on
			o.Clientid = c.ClientId;
go

select OrderId, OrderNumber, Amount
from dbo.vOrders2 
where OrderId = 1
go

/*** Solution 2 - Trusted FK constraint ***/
alter table dbo.Orders 
with check
add constraint FK_Orders_Clients
foreign key(ClientId)
references dbo.Clients(ClientId)
go

select OrderId, OrderNumber, Amount
from dbo.vOrders 
where OrderId = 1
go

