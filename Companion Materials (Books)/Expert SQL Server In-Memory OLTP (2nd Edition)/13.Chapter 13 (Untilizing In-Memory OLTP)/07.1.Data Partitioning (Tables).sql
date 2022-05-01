/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 13: Utilizing In-Memory OLTP                     */
/*                   07.Data Partitioning (Objects)                         */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop proc if exists dbo.GetTopCustomers;
drop proc if exists dbo.DeleteCustomersAndOrders;
drop proc if exists dbo.InsertCustomers_NativelyCompiled;
drop proc if exists dbo.UpdateCustomers;
drop proc if exists dbo.InsertOrders2017_06;
drop proc if exists dbo.UpdateOrders2017_06;
drop proc if exists dbo.DeleteOrders2017_06;
drop proc if exists dbo.UpdateOrders2017;
drop proc if exists dbo.DeleteOrders2017;
drop table if exists #Numbers;
if exists (select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders' and s.name = 'dbo') drop table dbo.Orders;
drop view if exists dbo.Orders;
drop table if exists dbo.Orders2017_07;
drop table if exists dbo.Orders2017_06;
drop table if exists dbo.Orders2017_05;
drop table if exists dbo.Orders2017;
drop table if exists dbo.Orders2016;
drop table if exists dbo.Customers;
drop table if exists dbo.OrdersUpdateQueue;
drop table if exists dbo.OrdersDeleteQueue;
if exists(select * from sys.partition_schemes where name = 'ps2017') drop partition scheme ps2017;
if exists(select * from sys.partition_schemes where name = 'ps2016') drop partition scheme ps2016;
if exists(select * from sys.partition_functions where name = 'pf2017') drop partition function pf2017;
if exists(select * from sys.partition_functions where name = 'pf2016') drop partition function pf2016;
go

-- Catalog Entity
create table dbo.Customers
(
	CustomerId int not null
		constraint PK_Customers
		primary key nonclustered hash
		with (bucket_count=65536),
	Name nvarchar(256) not null, 

	index IDX_Customers_Name
	nonclustered(Name)
)
with (memory_optimized=on, durability=schema_and_data)
go

-- Storing data for 2017_06
create table dbo.Orders2017_06
(
	OrderId bigint identity(1,1) not null,
	OrderDate datetime2(0) not null,
	CustomerId int not null,
	Amount money not null,
	Status tinyint not null,

	/* Other columns */
	constraint PK_Orders2017_06
	primary key nonclustered (OrderId),
	
	index IDX_Orders2017_06_CustomerId
	nonclustered hash(CustomerId)
	with (bucket_count=65536),

	constraint CHK_Orders2017_06
	check (OrderDate >= '2017-06-01' and OrderDate < '2017-07-01'),

	constraint FK_Orders2017_06_Customers
	foreign key(CustomerId)
	references dbo.Customers(CustomerId)
)
with (memory_optimized=on, durability=schema_and_data)
go

-- Storing data for 2017_05
create table dbo.Orders2017_05
(
	OrderId bigint identity(1,1) not null,
	OrderDate datetime2(0) not null,
	CustomerId int not null,
	Amount money not null,
	Status tinyint not null,

	/* Other columns */
	constraint PK_Orders2017_05
	primary key nonclustered (OrderId),
	
	index IDX_Orders2017_05_CustomerId
	nonclustered hash(CustomerId)
	with (bucket_count=65536),

	constraint CHK_Orders2017_05
	check (OrderDate >= '2017-05-01' and OrderDate < '2017-06-01'),

	constraint FK_Orders2017_05_Customers
	foreign key(CustomerId)
	references dbo.Customers(CustomerId)
)
with (memory_optimized=on, durability=schema_and_data)
go

create partition function pf2017(datetime2(0))
as range right for values 
('2017-02-01','2017-03-01','2017-04-01','2017-05-01','2017-06-01','2017-07-01'
,'2017-08-01','2017-09-01','2017-10-01','2017-11-01','2017-12-01','2018-01-01');
go

create partition scheme ps2017
as partition pf2017
all to ([FG2017]);
go

-- Storing data for 2017
create table dbo.Orders2017
(
	OrderId bigint not null, 
	OrderDate datetime2(0) not null,
	CustomerId int not null,
	Amount money not null,
	Status tinyint not null,

	constraint CHK_Order2017_01_05 check (OrderDate >= '2017-01-01' and OrderDate < '2017-05-01'),
	constraint CHK_Order2017_01_06 check (OrderDate >= '2017-01-01' and OrderDate < '2017-06-01'),
	constraint CHK_Order2017_01_07 check (OrderDate >= '2017-01-01' and OrderDate < '2017-07-01'),
	constraint CHK_Order2017_01_08 check (OrderDate >= '2017-01-01' and OrderDate < '2017-08-01'),
	constraint CHK_Order2017_01_09 check (OrderDate >= '2017-01-01' and OrderDate < '2017-09-01'),
	constraint CHK_Order2017_01_10 check (OrderDate >= '2017-01-01' and OrderDate < '2017-10-01'),
	constraint CHK_Order2017_01_11 check (OrderDate >= '2017-01-01' and OrderDate < '2017-11-01'),
	constraint CHK_Order2017_01_12 check (OrderDate >= '2017-01-01' and OrderDate < '2017-12-01'),
	constraint CHK_Order2017 check (OrderDate >= '2017-01-01' and OrderDate < '2018-01-01'),
)
go

create unique clustered index IDX_Orders2017_OrderDate_OrderId
on dbo.Orders2017(OrderDate, OrderId)
with (data_compression=row)
on ps2017(OrderDate)
go

create nonclustered index IDX_Orders2017_CustomerId
on  dbo.Orders2017(CustomerId)
with (data_compression=row)
on ps2017(OrderDate)
go

create nonclustered index IDX_Orders2017_OrderId
on  dbo.Orders2017(OrderId)
with (data_compression=row)
on ps2017(OrderDate)
go


create partition function pf2016(datetime2(0))
as range right for values 
('2016-02-01','2016-03-01','2016-04-01','2016-05-01','2016-06-01','2016-07-01'
,'2016-08-01','2016-09-01','2016-10-01','2016-11-01','2016-12-01','2017-01-01');
go

create partition scheme ps2016
as partition pf2016
all to ([FG2016]);
go

create table dbo.Orders2016
(
	OrderDate datetime2(0) not null,
	OrderId bigint not null,
	CustomerId int not null,
	Amount money not null,
	Status tinyint not null,

	constraint CHK_Order2016 check (OrderDate >= '2016-01-01' and OrderDate < '2017-01-01'),
)
on ps2016(OrderDate)
go

create clustered columnstore index CCI_Orders2016
on dbo.Orders2016
with (data_compression=columnstore_archive)
on ps2016(OrderDate)
go

-- Just to demo.. 
create nonclustered index IDX_Orders2016_CustomerId
on  dbo.Orders2016(CustomerId)
include(Amount)
with (data_compression=row)
on ps2016(OrderDate)
go

create view dbo.Orders(OrderDate, OrderId, CustomerId, Amount, Status)
as
	select OrderDate, OrderId, CustomerId, Amount, Status
	from dbo.Orders2017_06
	
	union all

	select OrderDate, OrderId, CustomerId, Amount, Status
	from dbo.Orders2017_05

	union all

	select OrderDate, OrderId, CustomerId, Amount, Status
	from dbo.Orders2017

	union all

	select OrderDate, OrderId, CustomerId, Amount, Status
	from dbo.Orders2016
go


/* Populating data */
create table #Numbers(Num int not null primary key);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,N6(C) as (select 0 from N5 as t1 cross join N1 as t2) -- 131,072 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N6)
insert into #Numbers
	select Id from Ids;

insert into dbo.Customers(CustomerId,Name)
	select Num, 'Customer ' + convert(varchar(6),Num)
	from #Numbers
	where Num <= 16384;

--First - setting identity seed for memory-optimized tables
set identity_insert dbo.Orders2017_06 on
insert into dbo.Orders2017_06(OrderDate, OrderId, CustomerId, Amount, Status)
values('2017-06-01',201706000000000,1,1,1);
delete from dbo.Orders2017_06;
set identity_insert dbo.Orders2017_06 off
go

set identity_insert dbo.Orders2017_05 on
insert into dbo.Orders2017_05(OrderDate, OrderId, CustomerId, Amount, Status)
values('2017-05-01',201705000000000,1,1,1);
delete from dbo.Orders2017_05;
set identity_insert dbo.Orders2017_05 off
go

insert into dbo.Orders2017_06(OrderDate, CustomerId, Amount, Status)
	select 
		dateadd(second,Num * 19,'2017-06-01') 
		,Num % 16384 + 1
		,10000.00 * rand()
		,1
	from #Numbers;

insert into dbo.Orders2017_05(OrderDate, CustomerId, Amount, Status)
	select 
		dateadd(second,Num * 19,'2017-05-01')
		,Num % 16384 + 1
		,10000.00 * rand()
		,1
	from #Numbers;

insert into dbo.Orders2017(OrderDate, OrderId, CustomerId, Amount, Status)
	select 
		dateadd(second,Num * 77,'2017-01-01')
		,201701000000000 + Num
		,Num % 16384 + 1
		,10000.00 * rand()
		,1
	from #Numbers

insert into dbo.Orders2016(OrderDate, OrderId, CustomerId, Amount, Status)
	select 
		dateadd(minute,Num * 4,'2016-01-01')
		,201601000000000 + Num
		,Num % 16384 + 1
		,10000.00 * rand()
		,1
	from #Numbers;
go

-- Compressing columnstore index
alter index CCI_Orders2016 on dbo.Orders2016 rebuild;
go

/* Execution Plans */
select count(*)
from dbo.Orders 
where OrderDate between '2017-06-02' and '2017-06-03';

select count(*)
from dbo.Orders 
where OrderDate >= '2017-01-01';

select count(*)
from dbo.Orders 
go
