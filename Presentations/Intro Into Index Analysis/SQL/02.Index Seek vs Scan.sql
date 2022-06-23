/****************************************************************************/
/*                        Intro into Index Analysis                         */
/*																			*/
/*                         Dmitri V. Korotkevitch                           */
/*                        http://aboutsqlserver.com                         */
/*                          dk@aboutsqlserver.com                           */
/****************************************************************************/
/*					     Index Seek vs. Index Scan                          */
/****************************************************************************/

use SQLServerInternals
go


-- Enable "Include Actual Execution Plan"
set statistics io on

select count(*) 
from dbo.Orders with (index = 1)

select count(*) 
from dbo.Orders with (index = 1)
where OrderId > 0;

set statistics io off
go

select top 3 *
from dbo.Orders
order by OrderId;
go

select *
from dbo.Orders
where
	OrderId between 1 and 10000 and
	OrderNum like '%12%';
go

set statistics io on

select count(*)
from dbo.Orders
where Year(OrderDate) = 2019 and Month(OrderDate) = 2;

select count(*)
from dbo.Orders
where OrderDate >= '2019-02-01' and OrderDate < '2019-03-01';

set statistics io off
go

select count(*)
from dbo.Orders 
where OrderNum like '%12%';

select count(*)
from dbo.Orders 
where OrderNum like '12%';
go

create table dbo.Customers
(
	CustomerId uniqueidentifier not null,
	constraint PK_Customers
	primary key(CustomerId)
);

insert into dbo.Customers(CustomerId)
	select distinct CustomerId from dbo.Orders;
go

alter table dbo.Orders
add constraint FK_Orders_Customers
foreign key(CustomerId)
references dbo.Customers(CustomerId);
go

delete from dbo.Customers
where CustomerId = newid();
go

drop index IDX_Orders_CustomerId on dbo.Orders
go

delete from dbo.Customers
where CustomerId = newid();
go

alter table dbo.Orders
drop constraint FK_Orders_Customers
go

create table dbo.Customers1
(
	CustomerId varchar(36) not null,
	constraint PK_Customers1
	primary key(CustomerId)
);

insert into dbo.Customers1(CustomerId)
	select convert(varchar(36),CustomerId) from dbo.Customers;
go

select count(*)
from dbo.Orders o join dbo.Customers c on
	o.CustomerId = c.CustomerId
where
	o.OrderId < 10;
go

select count(*)
from dbo.Orders o join dbo.Customers1 c on
	o.CustomerId = c.CustomerId
where
	o.OrderId < 10;
go

select count(*) 
from dbo.Orders 
where OrderNum = '123';

select count(*) 
from dbo.Orders 
where OrderNum = N'123';
go



