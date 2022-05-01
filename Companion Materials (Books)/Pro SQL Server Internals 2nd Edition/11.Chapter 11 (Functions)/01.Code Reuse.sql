/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 11. Functions                            */
/*                              Code Reuse                                  */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'usp_Orders_GetActiveOrders') drop proc dbo.usp_Orders_GetActiveOrders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Orders') drop table dbo.Orders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Clients') drop table dbo.Clients;
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
	IsActive bit not null,

	constraint PK_Orders
	primary key clustered(OrderId)
);

create index IDX_Orders_OrderNumber
on dbo.Orders(OrderNumber)
include(IsActive, Amount)
where IsActive = 1;
go

create proc dbo.usp_Orders_GetActiveOrders
as
	select o.OrderId, o.ClientId, c.ClientName, o.OrderDate, o.OrderNumber, o.Amount
	from dbo.Orders o join dbo.Clients c on
		o.Clientid = c.ClientId
	where IsActive = 1;
go

-- Check Execution plans
exec usp_Orders_GetActiveOrders;

select OrderId, OrderNumber, Amount
from dbo.Orders
where IsActive = 1;

