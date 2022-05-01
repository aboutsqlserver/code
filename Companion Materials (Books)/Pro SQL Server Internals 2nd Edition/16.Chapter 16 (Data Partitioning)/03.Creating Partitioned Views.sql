/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 16. Data Partitioning                       */
/*                       Creating Partitioned Views		                    */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'vProductSaleStats') drop view dbo.vProductSaleStats;
if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'Orders') drop view dbo.Orders;
if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'OrderLineItems') drop view dbo.OrderLineItems;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'OrderLineItems') drop table dbo.OrderLineItems;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Orders') drop table dbo.Orders;

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_01' and s.name = 'dbo') drop table dbo.OrderLineItems2014_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_02' and s.name = 'dbo') drop table dbo.OrderLineItems2014_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_03' and s.name = 'dbo') drop table dbo.OrderLineItems2014_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_04' and s.name = 'dbo') drop table dbo.OrderLineItems2014_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_05' and s.name = 'dbo') drop table dbo.OrderLineItems2014_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_06' and s.name = 'dbo') drop table dbo.OrderLineItems2014_06;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_07' and s.name = 'dbo') drop table dbo.OrderLineItems2014_07;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_08' and s.name = 'dbo') drop table dbo.OrderLineItems2014_08;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_09' and s.name = 'dbo') drop table dbo.OrderLineItems2014_09;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_10' and s.name = 'dbo') drop table dbo.OrderLineItems2014_10;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_11' and s.name = 'dbo') drop table dbo.OrderLineItems2014_11;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_12' and s.name = 'dbo') drop table dbo.OrderLineItems2014_12;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_01' and s.name = 'dbo') drop table dbo.OrderLineItems2015_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_02' and s.name = 'dbo') drop table dbo.OrderLineItems2015_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_03' and s.name = 'dbo') drop table dbo.OrderLineItems2015_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_04' and s.name = 'dbo') drop table dbo.OrderLineItems2015_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_05' and s.name = 'dbo') drop table dbo.OrderLineItems2015_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_06' and s.name = 'dbo') drop table dbo.OrderLineItems2015_06;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_07' and s.name = 'dbo') drop table dbo.OrderLineItems2015_07;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_08' and s.name = 'dbo') drop table dbo.OrderLineItems2015_08;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_09' and s.name = 'dbo') drop table dbo.OrderLineItems2015_09;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_10' and s.name = 'dbo') drop table dbo.OrderLineItems2015_10;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_11' and s.name = 'dbo') drop table dbo.OrderLineItems2015_11;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2015_12' and s.name = 'dbo') drop table dbo.OrderLineItems2015_12;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2016_01' and s.name = 'dbo') drop table dbo.OrderLineItems2016_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2016_02' and s.name = 'dbo') drop table dbo.OrderLineItems2016_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2016_03' and s.name = 'dbo') drop table dbo.OrderLineItems2016_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2016_04' and s.name = 'dbo') drop table dbo.OrderLineItems2016_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2016_05' and s.name = 'dbo') drop table dbo.OrderLineItems2016_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2016_06' and s.name = 'dbo') drop table dbo.OrderLineItems2016_06;


if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_01' and s.name = 'dbo') drop table dbo.Orders2014_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_02' and s.name = 'dbo') drop table dbo.Orders2014_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_03' and s.name = 'dbo') drop table dbo.Orders2014_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_04' and s.name = 'dbo') drop table dbo.Orders2014_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_05' and s.name = 'dbo') drop table dbo.Orders2014_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_06' and s.name = 'dbo') drop table dbo.Orders2014_06;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_07' and s.name = 'dbo') drop table dbo.Orders2014_07;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_08' and s.name = 'dbo') drop table dbo.Orders2014_08;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_09' and s.name = 'dbo') drop table dbo.Orders2014_09;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_10' and s.name = 'dbo') drop table dbo.Orders2014_10;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_11' and s.name = 'dbo') drop table dbo.Orders2014_11;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_12' and s.name = 'dbo') drop table dbo.Orders2014_12;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_01' and s.name = 'dbo') drop table dbo.Orders2015_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_02' and s.name = 'dbo') drop table dbo.Orders2015_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_03' and s.name = 'dbo') drop table dbo.Orders2015_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_04' and s.name = 'dbo') drop table dbo.Orders2015_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_05' and s.name = 'dbo') drop table dbo.Orders2015_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_06' and s.name = 'dbo') drop table dbo.Orders2015_06;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_07' and s.name = 'dbo') drop table dbo.Orders2015_07;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_08' and s.name = 'dbo') drop table dbo.Orders2015_08;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_09' and s.name = 'dbo') drop table dbo.Orders2015_09;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_10' and s.name = 'dbo') drop table dbo.Orders2015_10;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_11' and s.name = 'dbo') drop table dbo.Orders2015_11;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2015_12' and s.name = 'dbo') drop table dbo.Orders2015_12;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2016_01' and s.name = 'dbo') drop table dbo.Orders2016_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2016_02' and s.name = 'dbo') drop table dbo.Orders2016_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2016_03' and s.name = 'dbo') drop table dbo.Orders2016_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2016_04' and s.name = 'dbo') drop table dbo.Orders2016_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2016_05' and s.name = 'dbo') drop table dbo.Orders2016_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2016_06' and s.name = 'dbo') drop table dbo.Orders2016_06;
go

create table dbo.Orders2014_01
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_01
	primary key clustered(OrderId),
	--with (data_compression=page),

	constraint CHK_Orders2014_01
	check (OrderDate >= '2014-01-01' and OrderDate < '2014-02-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_01_CustomerId
on dbo.Orders2014_01(CustomerId) 
on [FG2014];

create table dbo.Orders2014_02
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_02
	primary key clustered(OrderId),

	constraint CHK_Orders2014_02
	check (OrderDate >= '2014-02-01' and OrderDate < '2014-03-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_02_CustomerId
on dbo.Orders2014_02(CustomerId) 
on [FG2014];


create table dbo.Orders2014_03
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_03
	primary key clustered(OrderId),

	constraint CHK_Orders2014_03
	check (OrderDate >= '2014-03-01' and OrderDate < '2014-04-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_03_CustomerId
on dbo.Orders2014_03(CustomerId) 
on [FG2014];

create table dbo.Orders2014_04
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_04
	primary key clustered(OrderId),

	constraint CHK_Orders2014_04
	check (OrderDate >= '2014-04-01' and OrderDate < '2014-05-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_04_CustomerId
on dbo.Orders2014_04(CustomerId) 
on [FG2014];

create table dbo.Orders2014_05
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_05
	primary key clustered(OrderId),

	constraint CHK_Orders2014_05
	check (OrderDate >= '2014-05-01' and OrderDate < '2014-06-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_05_CustomerId
on dbo.Orders2014_05(CustomerId) 
on [FG2014];


create table dbo.Orders2014_06
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_06
	primary key clustered(OrderId),

	constraint CHK_Orders2014_06
	check (OrderDate >= '2014-06-01' and OrderDate < '2014-07-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_06_CustomerId
on dbo.Orders2014_06(CustomerId) 
on [FG2014];

create table dbo.Orders2014_07
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_07
	primary key clustered(OrderId),

	constraint CHK_Orders2014_07
	check (OrderDate >= '2014-07-01' and OrderDate < '2014-08-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_07_CustomerId
on dbo.Orders2014_06(CustomerId) 
on [FG2014];

create table dbo.Orders2014_08
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_08
	primary key clustered(OrderId),

	constraint CHK_Orders2014_08
	check (OrderDate >= '2014-08-01' and OrderDate < '2014-09-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_08_CustomerId
on dbo.Orders2014_08(CustomerId) 
on [FG2014];

create table dbo.Orders2014_09
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_09
	primary key clustered(OrderId),

	constraint CHK_Orders2014_09
	check (OrderDate >= '2014-09-01' and OrderDate < '2014-10-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_09_CustomerId
on dbo.Orders2014_09(CustomerId) 
on [FG2014];

create table dbo.Orders2014_10
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_10
	primary key clustered(OrderId),

	constraint CHK_Orders2014_10
	check (OrderDate >= '2014-10-01' and OrderDate < '2014-11-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_10_CustomerId
on dbo.Orders2014_10(CustomerId) 
on [FG2014];

create table dbo.Orders2014_11
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_11
	primary key clustered(OrderId),

	constraint CHK_Orders2014_11
	check (OrderDate >= '2014-11-01' and OrderDate < '2014-12-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_11_CustomerId
on dbo.Orders2014_11(CustomerId) 
on [FG2014];

create table dbo.Orders2014_12
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2014_12
	primary key clustered(OrderId),

	constraint CHK_Orders2014_12
	check (OrderDate >= '2014-12-01' and OrderDate < '2015-01-01')
) on [FG2014];

create nonclustered index IDX_Orders2014_12_CustomerId
on dbo.Orders2014_12(CustomerId) 
on [FG2014];


create table dbo.Orders2015_01
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_01
	primary key clustered(OrderId),

	constraint CHK_Orders2015_01
	check (OrderDate >= '2015-01-01' and OrderDate < '2015-02-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_01_CustomerId
on dbo.Orders2015_01(CustomerId) 
on [FG2015];

create table dbo.Orders2015_02
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_02
	primary key clustered(OrderId),

	constraint CHK_Orders2015_02
	check (OrderDate >= '2015-02-01' and OrderDate < '2015-03-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_02_CustomerId
on dbo.Orders2015_02(CustomerId) 
on [FG2015];


create table dbo.Orders2015_03
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_03
	primary key clustered(OrderId),

	constraint CHK_Orders2015_03
	check (OrderDate >= '2015-03-01' and OrderDate < '2015-04-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_03_CustomerId
on dbo.Orders2015_03(CustomerId) 
on [FG2015];

create table dbo.Orders2015_04
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_04
	primary key clustered(OrderId),

	constraint CHK_Orders2015_04
	check (OrderDate >= '2015-04-01' and OrderDate < '2015-05-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_04_CustomerId
on dbo.Orders2015_04(CustomerId) 
on [FG2015];

create table dbo.Orders2015_05
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_05
	primary key clustered(OrderId),

	constraint CHK_Orders2015_05
	check (OrderDate >= '2015-05-01' and OrderDate < '2015-06-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_05_CustomerId
on dbo.Orders2015_05(CustomerId) 
on [FG2015];


create table dbo.Orders2015_06
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_06
	primary key clustered(OrderId),

	constraint CHK_Orders2015_06
	check (OrderDate >= '2015-06-01' and OrderDate < '2015-07-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_06_CustomerId
on dbo.Orders2015_06(CustomerId) 
on [FG2015];

create table dbo.Orders2015_07
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_07
	primary key clustered(OrderId),

	constraint CHK_Orders2015_07
	check (OrderDate >= '2015-07-01' and OrderDate < '2015-08-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_07_CustomerId
on dbo.Orders2015_06(CustomerId) 
on [FG2015];

create table dbo.Orders2015_08
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_08
	primary key clustered(OrderId),

	constraint CHK_Orders2015_08
	check (OrderDate >= '2015-08-01' and OrderDate < '2015-09-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_08_CustomerId
on dbo.Orders2015_08(CustomerId) 
on [FG2015];

create table dbo.Orders2015_09
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_09
	primary key clustered(OrderId),

	constraint CHK_Orders2015_09
	check (OrderDate >= '2015-09-01' and OrderDate < '2015-10-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_09_CustomerId
on dbo.Orders2015_09(CustomerId) 
on [FG2015];

create table dbo.Orders2015_10
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_10
	primary key clustered(OrderId),

	constraint CHK_Orders2015_10
	check (OrderDate >= '2015-10-01' and OrderDate < '2015-11-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_10_CustomerId
on dbo.Orders2015_10(CustomerId) 
on [FG2015];

create table dbo.Orders2015_11
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_11
	primary key clustered(OrderId),

	constraint CHK_Orders2015_11
	check (OrderDate >= '2015-11-01' and OrderDate < '2015-12-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_11_CustomerId
on dbo.Orders2015_11(CustomerId) 
on [FG2015];

create table dbo.Orders2015_12
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2015_12
	primary key clustered(OrderId),

	constraint CHK_Orders2015_12
	check (OrderDate >= '2015-12-01' and OrderDate < '2016-01-01')
) on [FG2015];

create nonclustered index IDX_Orders2015_12_CustomerId
on dbo.Orders2015_12(CustomerId) 
on [FG2015];


create table dbo.Orders2016_01
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2016_01
	primary key clustered(OrderId),

	constraint CHK_Orders2016_01
	check (OrderDate >= '2016-01-01' and OrderDate < '2016-02-01')
) on [FG2016];

create nonclustered index IDX_Orders2016_01_CustomerId
on dbo.Orders2016_01(CustomerId) 
on [FG2016];

create table dbo.Orders2016_02
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2016_02
	primary key clustered(OrderId),

	constraint CHK_Orders2016_02
	check (OrderDate >= '2016-02-01' and OrderDate < '2016-03-01')
) on [FG2016];

create nonclustered index IDX_Orders2016_02_CustomerId
on dbo.Orders2016_02(CustomerId) 
on [FG2016];


create table dbo.Orders2016_03
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2016_03
	primary key clustered(OrderId),

	constraint CHK_Orders2016_03
	check (OrderDate >= '2016-03-01' and OrderDate < '2016-04-01')
) on [FG2016];

create nonclustered index IDX_Orders2016_03_CustomerId
on dbo.Orders2016_03(CustomerId) 
on [FG2016];

create table dbo.Orders2016_04
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2016_04
	primary key clustered(OrderId),

	constraint CHK_Orders2016_04
	check (OrderDate >= '2016-04-01' and OrderDate < '2016-05-01')
) on [FG2016];

create nonclustered index IDX_Orders2016_04_CustomerId
on dbo.Orders2016_04(CustomerId) 
on [FG2016];



create table dbo.Orders2016_05
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2016_05
	primary key clustered(OrderId),

	constraint CHK_Orders2016_05
	check (OrderDate >= '2016-05-01' and OrderDate < '2016-06-01')
) on [FASTSTORAGE];

create nonclustered index IDX_Orders2016_04_CustomerId
on dbo.Orders2016_05(CustomerId) 
on [FASTSTORAGE]
go

create table dbo.Orders2016_06
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2016_06
	primary key clustered(OrderId),

	constraint CHK_Orders2016_06
	check (OrderDate >= '2016-06-01' and OrderDate < '2016-07-01')
) on [FASTSTORAGE];

create nonclustered index IDX_Orders2016_04_CustomerId
on dbo.Orders2016_06(CustomerId) 
on [FASTSTORAGE]
go

create view dbo.Orders(OrderId, OrderDate, OrderNum
	,OrderTotal, CustomerId /*Other Columns*/)
with schemabinding
as
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_01
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_02
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_03
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_04
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_05
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_06
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_07
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_08
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_09
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_10
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_11
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2014_12
					
	/* union all -- Other tables */
	union all

	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_01
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_02
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_03
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_04
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_05
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_06
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_07
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_08
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_09
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_10
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_11
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2015_12    
	
	union all

	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2016_01
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2016_02
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2016_03
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2016_04
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2016_05

	union all 

	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2016_06
go



create table dbo.OrderLineItems2014_01
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_01
	check (OrderDate >= '2014-01-01' and OrderDate < '2014-02-01'),

	constraint FK_OrderLineItems_Orders_2014_01
	foreign key(OrderId)
	references dbo.Orders2014_01(OrderId),
);

create unique clustered index IDX_Orders2014_01_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_01(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_01_ArticleId
on dbo.OrderLineItems2014_01(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2014_02
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_02
	check (OrderDate >= '2014-02-01' and OrderDate < '2014-03-01'),

	constraint FK_OrderLineItems_Orders_2014_02
	foreign key(OrderId)
	references dbo.Orders2014_02(OrderId),
);

create unique clustered index IDX_Orders2014_02_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_02(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_02_ArticleId
on dbo.OrderLineItems2014_02(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2014_03
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_03
	check (OrderDate >= '2014-03-01' and OrderDate < '2014-04-01'),

	constraint FK_OrderLineItems_Orders_2014_03
	foreign key(OrderId)
	references dbo.Orders2014_03(OrderId),
);

create unique clustered index IDX_Orders2014_03_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_03(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_03_ArticleId
on dbo.OrderLineItems2014_03(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2014_04
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_04
	check (OrderDate >= '2014-04-01' and OrderDate < '2014-05-01'),

	constraint FK_OrderLineItems_Orders_2014_04
	foreign key(OrderId)
	references dbo.Orders2014_04(OrderId),
);

create unique clustered index IDX_Orders2014_04_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_04(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_04_ArticleId
on dbo.OrderLineItems2014_04(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2014_05
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_05
	check (OrderDate >= '2014-05-01' and OrderDate < '2014-06-01'),

	constraint FK_OrderLineItems_Orders_2014_05
	foreign key(OrderId)
	references dbo.Orders2014_05(OrderId),
);

create unique clustered index IDX_Orders2014_05_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_05(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_05_ArticleId
on dbo.OrderLineItems2014_05(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2014_06
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_06
	check (OrderDate >= '2014-06-01' and OrderDate < '2014-07-01'),

	constraint FK_OrderLineItems_Orders_2014_06
	foreign key(OrderId)
	references dbo.Orders2014_06(OrderId),
);

create unique clustered index IDX_Orders2014_06_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_06(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_06_ArticleId
on dbo.OrderLineItems2014_06(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2014_07
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_07
	check (OrderDate >= '2014-07-01' and OrderDate < '2014-08-01'),

	constraint FK_OrderLineItems_Orders_2014_07
	foreign key(OrderId)
	references dbo.Orders2014_07(OrderId),
);

create unique clustered index IDX_Orders2014_07_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_07(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_07_ArticleId
on dbo.OrderLineItems2014_07(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2014_08
(
	OrderId int not null,

	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_08
	check (OrderDate >= '2014-08-01' and OrderDate < '2014-09-01'),

	constraint FK_OrderLineItems_Orders_2014_08
	foreign key(OrderId)
	references dbo.Orders2014_08(OrderId),
);

create unique clustered index IDX_Orders2014_08_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_08(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_08_ArticleId
on dbo.OrderLineItems2014_08(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2014_09
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_09
	check (OrderDate >= '2014-09-01' and OrderDate < '2014-10-01'),

	constraint FK_OrderLineItems_Orders_2014_09
	foreign key(OrderId)
	references dbo.Orders2014_09(OrderId),
);

create unique clustered index IDX_Orders2014_09_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_09(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_09_ArticleId
on dbo.OrderLineItems2014_09(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2014_10
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_10
	check (OrderDate >= '2014-10-01' and OrderDate < '2014-11-01'),

	constraint FK_OrderLineItems_Orders_2014_10
	foreign key(OrderId)
	references dbo.Orders2014_10(OrderId),
);

create unique clustered index IDX_Orders2014_10_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_10(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_10_ArticleId
on dbo.OrderLineItems2014_10(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2014_11
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_11
	check (OrderDate >= '2014-11-01' and OrderDate < '2014-12-01'),

	constraint FK_OrderLineItems_Orders_2014_11
	foreign key(OrderId)
	references dbo.Orders2014_11(OrderId),
);

create unique clustered index IDX_Orders2014_11_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_11(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_11_ArticleId
on dbo.OrderLineItems2014_11(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2014_12
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2014_12
	check (OrderDate >= '2014-12-01' and OrderDate < '2015-01-01'),

	constraint FK_OrderLineItems_Orders_2014_12
	foreign key(OrderId)
	references dbo.Orders2014_12(OrderId),
);

create unique clustered index IDX_Orders2014_12_OrderId_OrderLineItemId
on dbo.OrderLineItems2014_12(OrderId, OrderLineItemId) 
on [FG2014];

create nonclustered index IDX_Orders2014_12_ArticleId
on dbo.OrderLineItems2014_12(ArticleId) 
on [FG2014];

create table dbo.OrderLineItems2015_01
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_01
	check (OrderDate >= '2015-01-01' and OrderDate < '2015-02-01'),

	constraint FK_OrderLineItems_Orders_2015_01
	foreign key(OrderId)
	references dbo.Orders2015_01(OrderId),
);

create unique clustered index IDX_Orders2015_01_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_01(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_01_ArticleId
on dbo.OrderLineItems2015_01(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2015_02
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_02
	check (OrderDate >= '2015-02-01' and OrderDate < '2015-03-01'),

	constraint FK_OrderLineItems_Orders_2015_02
	foreign key(OrderId)
	references dbo.Orders2015_02(OrderId),
);

create unique clustered index IDX_Orders2015_02_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_02(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_02_ArticleId
on dbo.OrderLineItems2015_02(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2015_03
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_03
	check (OrderDate >= '2015-03-01' and OrderDate < '2015-04-01'),

	constraint FK_OrderLineItems_Orders_2015_03
	foreign key(OrderId)
	references dbo.Orders2015_03(OrderId),
);

create unique clustered index IDX_Orders2015_03_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_03(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_03_ArticleId
on dbo.OrderLineItems2015_03(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2015_04
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_04
	check (OrderDate >= '2015-04-01' and OrderDate < '2015-05-01'),

	constraint FK_OrderLineItems_Orders_2015_04
	foreign key(OrderId)
	references dbo.Orders2015_04(OrderId),
);

create unique clustered index IDX_Orders2015_04_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_04(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_04_ArticleId
on dbo.OrderLineItems2015_04(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2015_05
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_05
	check (OrderDate >= '2015-05-01' and OrderDate < '2015-06-01'),

	constraint FK_OrderLineItems_Orders_2015_05
	foreign key(OrderId)
	references dbo.Orders2015_05(OrderId),
);

create unique clustered index IDX_Orders2015_05_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_05(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_05_ArticleId
on dbo.OrderLineItems2015_05(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2015_06
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_06
	check (OrderDate >= '2015-06-01' and OrderDate < '2015-07-01'),

	constraint FK_OrderLineItems_Orders_2015_06
	foreign key(OrderId)
	references dbo.Orders2015_06(OrderId),
);

create unique clustered index IDX_Orders2015_06_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_06(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_06_ArticleId
on dbo.OrderLineItems2015_06(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2015_07
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_07
	check (OrderDate >= '2015-07-01' and OrderDate < '2015-08-01'),

	constraint FK_OrderLineItems_Orders_2015_07
	foreign key(OrderId)
	references dbo.Orders2015_07(OrderId),
);

create unique clustered index IDX_Orders2015_07_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_07(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_07_ArticleId
on dbo.OrderLineItems2015_07(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2015_08
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_08
	check (OrderDate >= '2015-08-01' and OrderDate < '2015-09-01'),

	constraint FK_OrderLineItems_Orders_2015_08
	foreign key(OrderId)
	references dbo.Orders2015_08(OrderId),
);

create unique clustered index IDX_Orders2015_08_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_08(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_08_ArticleId
on dbo.OrderLineItems2015_08(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2015_09
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_09
	check (OrderDate >= '2015-09-01' and OrderDate < '2015-10-01'),

	constraint FK_OrderLineItems_Orders_2015_09
	foreign key(OrderId)
	references dbo.Orders2015_09(OrderId),
);

create unique clustered index IDX_Orders2015_09_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_09(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_09_ArticleId
on dbo.OrderLineItems2015_09(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2015_10
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_10
	check (OrderDate >= '2015-10-01' and OrderDate < '2015-11-01'),

	constraint FK_OrderLineItems_Orders_2015_10
	foreign key(OrderId)
	references dbo.Orders2015_10(OrderId),
);

create unique clustered index IDX_Orders2015_10_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_10(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_10_ArticleId
on dbo.OrderLineItems2015_10(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2015_11
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_11
	check (OrderDate >= '2015-11-01' and OrderDate < '2015-12-01'),

	constraint FK_OrderLineItems_Orders_2015_11
	foreign key(OrderId)
	references dbo.Orders2015_11(OrderId),
);

create unique clustered index IDX_Orders2015_11_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_11(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_11_ArticleId
on dbo.OrderLineItems2015_11(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2015_12
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2015_12
	check (OrderDate >= '2015-12-01' and OrderDate < '2016-01-01'),

	constraint FK_OrderLineItems_Orders_2015_12
	foreign key(OrderId)
	references dbo.Orders2015_12(OrderId),
);

create unique clustered index IDX_Orders2015_12_OrderId_OrderLineItemId
on dbo.OrderLineItems2015_12(OrderId, OrderLineItemId) 
on [FG2015];

create nonclustered index IDX_Orders2015_12_ArticleId
on dbo.OrderLineItems2015_12(ArticleId) 
on [FG2015];

create table dbo.OrderLineItems2016_01
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2016_01
	check (OrderDate >= '2016-01-01' and OrderDate < '2016-02-01'),

	constraint FK_OrderLineItems_Orders_2016_01
	foreign key(OrderId)
	references dbo.Orders2016_01(OrderId),
);

create unique clustered index IDX_Orders2016_01_OrderId_OrderLineItemId
on dbo.OrderLineItems2016_01(OrderId, OrderLineItemId) 
on [FG2016];

create nonclustered index IDX_Orders2016_01_ArticleId
on dbo.OrderLineItems2016_01(ArticleId) 
on [FG2016];

create table dbo.OrderLineItems2016_02
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2016_02
	check (OrderDate >= '2016-02-01' and OrderDate < '2016-03-01'),

	constraint FK_OrderLineItems_Orders_2016_02
	foreign key(OrderId)
	references dbo.Orders2016_02(OrderId),
);

create unique clustered index IDX_Orders2016_02_OrderId_OrderLineItemId
on dbo.OrderLineItems2016_02(OrderId, OrderLineItemId) 
on [FG2016];

create nonclustered index IDX_Orders2016_02_ArticleId
on dbo.OrderLineItems2016_02(ArticleId) 
on [FG2016];

create table dbo.OrderLineItems2016_03
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2016_03
	check (OrderDate >= '2016-03-01' and OrderDate < '2016-04-01'),

	constraint FK_OrderLineItems_Orders_2016_03
	foreign key(OrderId)
	references dbo.Orders2016_03(OrderId),
);

create unique clustered index IDX_Orders2016_03_OrderId_OrderLineItemId
on dbo.OrderLineItems2016_03(OrderId, OrderLineItemId) 
on [FG2016];

create nonclustered index IDX_Orders2016_03_ArticleId
on dbo.OrderLineItems2016_03(ArticleId) 
on [FG2016];

create table dbo.OrderLineItems2016_04
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2016_04
	check (OrderDate >= '2016-04-01' and OrderDate < '2016-05-01'),

	constraint FK_OrderLineItems_Orders_2016_04
	foreign key(OrderId)
	references dbo.Orders2016_04(OrderId),
);

create unique clustered index IDX_Orders2016_04_OrderId_OrderLineItemId
on dbo.OrderLineItems2016_04(OrderId, OrderLineItemId) 
on [FG2016];

create nonclustered index IDX_Orders2016_04_ArticleId
on dbo.OrderLineItems2016_04(ArticleId) 
on [FG2016];

create table dbo.OrderLineItems2016_05
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2016_05
	check (OrderDate >= '2016-05-01' and OrderDate < '2016-06-01'),

	constraint FK_OrderLineItems_Orders_2016_05
	foreign key(OrderId)
	references dbo.Orders2016_05(OrderId),
);

create unique clustered index IDX_Orders2016_05_OrderId_OrderLineItemId
on dbo.OrderLineItems2016_05(OrderId, OrderLineItemId) 
on [FG2016];

create nonclustered index IDX_Orders2016_05_ArticleId
on dbo.OrderLineItems2016_05(ArticleId) 
on [FG2016];

create table dbo.OrderLineItems2016_06
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2016_06
	check (OrderDate >= '2016-06-01' and OrderDate < '2016-07-01'),

	constraint FK_OrderLineItems_Orders_2016_06
	foreign key(OrderId)
	references dbo.Orders2016_06(OrderId),
);

create unique clustered index IDX_Orders2016_06_OrderId_OrderLineItemId
on dbo.OrderLineItems2016_06(OrderId, OrderLineItemId) 
on [FG2016];

create nonclustered index IDX_Orders2016_06_ArticleId
on dbo.OrderLineItems2016_06(ArticleId) 
on [FG2016]
go

create view dbo.OrderLineItems(OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price)
with schemabinding 
as
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_01
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_02
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_03
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_04
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_05
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_06
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_07
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_08
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_09
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_10
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_11
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2014_12
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_01
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_02
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_03
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_04
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_05
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_06
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_07
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_08
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_09
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_10
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_11
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2015_12
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2016_01
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2016_02
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2016_03
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2016_04
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2016_05
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2016_06
go


/*** Querying Partitioned View ***/
-- Enable "Include Actual Execution Plan"
select count(*) from dbo.Orders;
select count(*) from dbo.Orders where OrderDate = '2016-06-03'
go


select o.OrderId, o.OrderNum, o.OrderDate, i.Quantity, i.Price
from dbo.Orders o join dbo.OrderLineItems i on
	o.OrderId = i.OrderId
where 
	o.OrderDate >= '2016-01-01' and
	o.OrderDate < '2016-02-01' and
	o.CustomerId = 1 and
	i.ArticleId = 2;

select o.OrderId, o.OrderNum, o.OrderDate, i.Quantity, i.Price
from dbo.Orders o join dbo.OrderLineItems i on
	o.OrderId = i.OrderId and
	o.OrderDate = i.OrderDate
where 
	o.OrderDate >= '2016-01-01' and
	o.OrderDate < '2016-02-01' and
	o.CustomerId = 1 and
	i.ArticleId = 2

