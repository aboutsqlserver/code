/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                        Chapter 08. Constraints                           */
/*                        Foreign Key Constraints                           */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'OrderItems') drop table dbo.OrderItems;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Orders') drop table dbo.Orders;
go

create table dbo.Orders
(
	OrderId int not null,
	Placeholder char(100) null,
			
	constraint PK_Orders
	primary key clustered(OrderId)
);
go

create table dbo.OrderItems
(
	OrderItemId int not null identity(1,1),
	OrderId int not null,
	Placeholder char(100) null,
			
	-- What would you use as CI in the real life?
	constraint PK_OrderItems
	primary key clustered(OrderItemId)
);
go
	
;with CTE(Num)
as
(
	select 1

	union all

	select Num + 1
	from CTE 
	where Num < 1000
)
insert into dbo.Orders(OrderId)
	select Num from CTE
option (MAXRECURSION 0);
go

alter table dbo.OrderItems
with check
add constraint FK_OrderItems_Orders
foreign key(OrderId)
references dbo.Orders(OrderId)
on update cascade
on delete cascade;
go

-- Enable "Include Actual Execution Plan"
insert into dbo.OrderItems(OrderId) values(1);
go

-- CI SCAN on OrderItems table
delete from dbo.Orders
where OrderId = 1;
go

create index IDX_OrderItems_OrderId
on dbo.OrderItems(OrderId);
go

-- NCI SEEK on OrderItems table
delete from dbo.Orders
where OrderId = 2;
go
