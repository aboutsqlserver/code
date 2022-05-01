/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 16. Data Partitioning                       */
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
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go


if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'Orders2') drop view dbo.Orders2;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2016_5' and s.name = 'dbo') drop table dbo.Orders2016_5
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2016_6' and s.name = 'dbo') drop table dbo.Orders2016_6
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014' and s.name = 'dbo') drop table dbo.Orders2014;
if exists(select * from sys.partition_schemes where name = 'psOrders2014') drop partition scheme psOrders2014;
if exists(select * from sys.partition_functions	where name = 'pfOrders2014') drop partition function pfOrders2014;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015' and s.name = 'dbo') drop table dbo.Orders2015;
if exists(select * from sys.partition_schemes where name = 'psOrders2015') drop partition scheme psOrders2015 ;
if exists(select * from sys.partition_functions	where name = 'pfOrders2015') drop partition function pfOrders2015;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2016' and s.name = 'dbo') drop table dbo.Orders2016;
if exists(select * from sys.partition_schemes where name = 'psOrders2016') drop partition scheme psOrders2016; 
if exists(select * from sys.partition_functions	where name = 'pfOrders2016') drop partition function pfOrders2016;
go

create partition function pfOrders2014(datetime)
as range right for values 
('2014-02-01', '2014-03-01','2014-04-01','2014-05-01','2014-06-01'
,'2014-07-01','2014-08-01','2014-09-01','2014-10-01','2014-11-01'
,'2014-12-01');
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
	check(OrderDate >= '2014-01-01' and OrderDate < '2015-01-01')
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

create partition function pfOrders2015(datetime)
as range right for values 
('2015-02-01', '2015-03-01','2015-04-01','2015-05-01','2015-06-01'
,'2015-07-01','2015-08-01','2015-09-01','2015-10-01','2015-11-01'
,'2015-12-01')
go

create partition scheme psOrders2015 
as partition pfOrders2015
all to ([FG2015]);
go

create table dbo.Orders2015
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint CHK_Orders2015
	check(OrderDate >= '2015-01-01' and OrderDate < '2016-01-01')
);

create unique clustered index IDX_Orders2015_OrderDate_OrderId
on dbo.Orders2015(OrderDate, OrderId) 
--with (data_compression = page)
on psOrders2015(OrderDate);

create nonclustered index IDX_Orders2015_CustomerId
on dbo.Orders2015(CustomerId) 
--with (data_compression = page)
on psOrders2015(OrderDate);
go

create partition function pfOrders2016(datetime)
as range right for values 
('2016-02-01', '2016-03-01','2016-04-01','2016-05-01','2016-06-01'
,'2016-07-01','2016-08-01','2016-09-01','2016-10-01','2016-11-01'
,'2016-12-01');
go

create partition scheme psOrders2016 
as partition pfOrders2016
all to ([FG2016]);
go

create table dbo.Orders2016
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint CHK_Orders2016
	check(OrderDate >= '2016-01-01' and OrderDate < '2016-05-01')
);

create unique clustered index IDX_Orders2016_OrderDate_OrderId
on dbo.Orders2016(OrderDate, OrderId) 
--with (data_compression = page)
on psOrders2016(OrderDate);

create nonclustered index IDX_Orders2016_CustomerId
on dbo.Orders2016(CustomerId) 
--with (data_compression = page)
on psOrders2016(OrderDate);
go

create table dbo.Orders2016_5
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint CHK_Orders2016_5
	check(OrderDate >= '2016-05-01' and OrderDate < '2016-06-01')
);

create unique clustered index IDX_Orders2016_5_OrderDate_OrderId
on dbo.Orders2016_5(OrderDate, OrderId) 
--with (data_compression = row)
on [FASTSTORAGE];

create nonclustered index IDX_Orders2016_5_CustomerId
on dbo.Orders2016_5(CustomerId) 
--with (data_compression = row)
on [FASTSTORAGE]
go

create table dbo.Orders2016_6
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint CHK_Orders2016_6
	check(OrderDate >= '2016-06-01' and OrderDate < '2016-07-01')
);

create unique clustered index IDX_Orders2016_6_OrderDate_OrderId
on dbo.Orders2016_6(OrderDate, OrderId) 
--with (data_compression = row)
on [FASTSTORAGE];

create nonclustered index IDX_Orders2016_6_CustomerId
on dbo.Orders2016_6(CustomerId) 
--with (data_compression = row)
on [FASTSTORAGE]
go

create view dbo.Orders2(OrderId, OrderDate, OrderNum
	,OrderTotal, CustomerId /*Other Columns*/)
with schemabinding
as
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2016
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2016_5
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2016_6
go

