/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                      Chapter 15. Data Partitioning                       */
/*               Using Partitioned Tables and Views Together                */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*			This script requires Enterprise Edition of SQL Server.			*/
/****************************************************************************/

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

if exists(
	select *
	from sys.views v join sys.schemas s on
		v.schema_id = s.schema_id
	where
		v.name = 'Orders2' and s.name = 'dbo'
)
	drop view dbo.Orders2
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_5' and s.name = 'dbo') drop table dbo.Orders2014_5
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_6' and s.name = 'dbo') drop table dbo.Orders2014_6
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012' and s.name = 'dbo') drop table dbo.Orders2012
if exists(select * from sys.partition_schemes where name = 'psOrders2012') drop partition scheme psOrders2012 
if exists(select * from sys.partition_functions	where name = 'pfOrders2012') drop partition function pfOrders2012
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013' and s.name = 'dbo') drop table dbo.Orders2013
if exists(select * from sys.partition_schemes where name = 'psOrders2013') drop partition scheme psOrders2013 
if exists(select * from sys.partition_functions	where name = 'pfOrders2013') drop partition function pfOrders2013
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014' and s.name = 'dbo') drop table dbo.Orders2014
if exists(select * from sys.partition_schemes where name = 'psOrders2014') drop partition scheme psOrders2014 
if exists(select * from sys.partition_functions	where name = 'pfOrders2014') drop partition function pfOrders2014
go

create partition function pfOrders2012(datetime)
as range right for values 
('2012-02-01', '2012-03-01','2012-04-01','2012-05-01','2012-06-01'
,'2012-07-01','2012-08-01','2012-09-01','2012-10-01','2012-11-01'
,'2012-12-01')
go

create partition scheme psOrders2012 
as partition pfOrders2012
all to ([FG2012])
go

create table dbo.Orders2012
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint CHK_Orders2012
	check(OrderDate >= '2012-01-01' and OrderDate < '2013-01-01')
);

create unique clustered index IDX_Orders2012_OrderDate_OrderId
on dbo.Orders2012(OrderDate, OrderId) 
--with (data_compression = page)
on psOrders2012(OrderDate);

create nonclustered index IDX_Orders2012_CustomerId
on dbo.Orders2012(CustomerId) 
--with (data_compression = page)
on psOrders2012(OrderDate);
go

create partition function pfOrders2013(datetime)
as range right for values 
('2013-02-01', '2013-03-01','2013-04-01','2013-05-01','2013-06-01'
,'2013-07-01','2013-08-01','2013-09-01','2013-10-01','2013-11-01'
,'2013-12-01')
go

create partition scheme psOrders2013 
as partition pfOrders2013
all to ([FG2013])
go

create table dbo.Orders2013
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint CHK_Orders2013
	check(OrderDate >= '2013-01-01' and OrderDate < '2014-01-01')
);

create unique clustered index IDX_Orders2013_OrderDate_OrderId
on dbo.Orders2013(OrderDate, OrderId) 
--with (data_compression = page)
on psOrders2013(OrderDate);

create nonclustered index IDX_Orders2013_CustomerId
on dbo.Orders2013(CustomerId) 
--with (data_compression = page)
on psOrders2013(OrderDate);
go

create partition function pfOrders2014(datetime)
as range right for values 
('2014-02-01', '2014-03-01','2014-04-01','2014-05-01','2014-06-01'
,'2014-07-01','2014-08-01','2014-09-01','2014-10-01','2014-11-01'
,'2014-12-01')
go

create partition scheme psOrders2014 
as partition pfOrders2014
all to ([FG2014])
go

create table dbo.Orders2014
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint CHK_Orders2014
	check(OrderDate >= '2014-01-01' and OrderDate < '2014-05-01')
);

create unique clustered index IDX_Orders2014_OrderDate_OrderId
on dbo.Orders2014(OrderDate, OrderId) 
--with (data_compression = page)
on psOrders2014(OrderDate);

create nonclustered index IDX_Orders2014_CustomerId
on dbo.Orders2014(CustomerId) 
--with (data_compression = page)
on psOrders2014(OrderDate);
go

create table dbo.Orders2014_5
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint CHK_Orders2014_5
	check(OrderDate >= '2014-05-01' and OrderDate < '2014-06-01')
);

create unique clustered index IDX_Orders2014_5_OrderDate_OrderId
on dbo.Orders2014_5(OrderDate, OrderId) 
--with (data_compression = row)
on [FASTSTORAGE];

create nonclustered index IDX_Orders2014_5_CustomerId
on dbo.Orders2014_5(CustomerId) 
--with (data_compression = row)
on [FASTSTORAGE]
go

create table dbo.Orders2014_6
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint CHK_Orders2014_6
	check(OrderDate >= '2014-06-01' and OrderDate < '2014-07-01')
);

create unique clustered index IDX_Orders2014_6_OrderDate_OrderId
on dbo.Orders2014_6(OrderDate, OrderId) 
--with (data_compression = row)
on [FASTSTORAGE];

create nonclustered index IDX_Orders2014_6_CustomerId
on dbo.Orders2014_6(CustomerId) 
--with (data_compression = row)
on [FASTSTORAGE]
go

create view dbo.Orders2(OrderId, OrderDate, OrderNum
	,OrderTotal, CustomerId /*Other Columns*/)
with schemabinding
as
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_5
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_6
go

