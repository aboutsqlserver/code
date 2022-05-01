/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*                    10.Example of Data Partitioning                       */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'InsertOrderLineItems') drop proc dbo.InsertOrderLineItems;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'DeleteOrder') drop proc dbo.DeleteOrder;
if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'Orders') drop view dbo.Orders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Orders') drop table dbo.Orders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'OldOrders') drop table dbo.OldOrders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'LastYearOrders') drop table dbo.LastYearOrders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'RecentOrders') drop table dbo.RecentOrders;
if exists(select * from sys.partition_schemes where name = 'psOldOrders') drop partition scheme psOldOrders;
if exists(select * from sys.partition_schemes where name = 'psLastYearOrders') drop partition scheme psLastYearOrders;
if exists(select * from sys.partition_functions where name = 'pfOldOrders') drop partition function pfOldOrders;
if exists(select * from sys.partition_functions where name = 'pfLastYearOrders') drop partition function pfLastYearOrders;
go

-- Storing Orders with OrderDate >= 2015-01-01
create table dbo.RecentOrders
(
	OrderId int not null identity(1,1),
	OrderDate datetime2(0) not null,
	OrderNum varchar(32) 
		collate Latin1_General_100_BIN2 not null,
	CustomerId int not null,
	Amount money not null,
	/* Other columns */
	constraint PK_RecentOrders
	primary key nonclustered hash(OrderId)
	with (bucket_count=1048576),
	
	index IDX_RecentOrders_CustomerId
	nonclustered(CustomerId)
)
with (memory_optimized=on, durability=schema_and_data)
go

create partition function pfLastYearOrders(datetime2(0))
as range right for values 
('2014-04-01','2014-07-01','2014-10-01','2015-01-01')
go


create partition scheme psLastYearOrders
as partition pfLastYearOrders
all to ([primary])
go

create table dbo.LastYearOrders
(
	OrderId int not null,
	OrderDate datetime2(0) not null,
	OrderNum varchar(32) 
		collate Latin1_General_100_BIN2 not null,
	CustomerId int not null,
	Amount money not null,
	/* Other columns */
	-- We have to include OrderDate to PK 
	-- due to partitioning
	constraint PK_LastYearOrders
	primary key clustered(OrderDate,OrderId)
	with (data_compression=row)
	on psLastYearOrders(OrderDate),

	constraint CHK_LastYearOrders
	check
	(
		OrderDate >= '2014-01-01' and 
		OrderDate < '2015-01-01'
	)
);
 
create nonclustered index IDX_LastYearOrders_CustomerId
on dbo.LastYearOrders(CustomerID)
with (data_compression=row)
on psLastYearOrders(OrderDate);
go


create partition function pfOldOrders(datetime2(0))
as range right for values 
(  /* Old intervals */
  '2012-10-01','2013-01-01','2013-04-01'
  ,'2013-07-01','2013-10-01','2014-01-01'
)
go


create partition scheme psOldOrders
as partition pfOldOrders
all to ([primary])
go

create table dbo.OldOrders
(
	OrderId int not null,
	OrderDate datetime2(0) not null,
	OrderNum varchar(32) 
		collate Latin1_General_100_BIN2 not null,
	CustomerId int not null,
	Amount money not null,
	/* Other columns */
	constraint CHK_OldOrders
	check(OrderDate < '2014-01-01')
)
on psOldOrders(OrderDate);
 
create clustered columnstore index CCI_OldOrders
on dbo.OldOrders
with (data_compression=columnstore_Archive)
on psOldOrders(OrderDate);
go

create view dbo.Orders(OrderId,OrderDate,
	OrderNum,CustomerId,Amount)
as
	select OrderId,OrderDate,OrderNum,CustomerId,Amount
	from dbo.RecentOrders
	where OrderDate >= '2015-01-01'
	
	union all

	select OrderId,OrderDate,OrderNum,CustomerId,Amount
	from dbo.LastYearOrders

	union all 

	select OrderId,OrderDate,OrderNum,CustomerId,Amount
	from dbo.OldOrders
go

select top 10 
	CustomerId, sum(Amount) as [TotalSales]
from dbo.Orders 
where 
	OrderDate >='2013-07-01' and 
	OrderDate < '2014-07-01'
group by 
	CustomerId
order by 
	sum(Amount) desc
