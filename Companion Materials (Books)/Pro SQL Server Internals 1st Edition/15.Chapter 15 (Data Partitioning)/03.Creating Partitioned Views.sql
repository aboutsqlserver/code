/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                      Chapter 15. Data Partitioning                       */
/*                       Creating Partitioned Views		                    */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists(
	select *
	from sys.views v join sys.schemas s on
		v.schema_id = s.schema_id
	where
		v.name = 'Orders' and s.name = 'dbo'
)
	drop view dbo.Orders
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'Orders' and s.name = 'dbo'
)
	drop table dbo.Orders
go

if exists(
	select *
	from sys.views v join sys.schemas s on
		v.schema_id = s.schema_id
	where
		v.name = 'OrderLineItems' and s.name = 'dbo'
)
	drop view dbo.OrderLineItems
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_01' and s.name = 'dbo') drop table dbo.OrderLineItems2012_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_02' and s.name = 'dbo') drop table dbo.OrderLineItems2012_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_03' and s.name = 'dbo') drop table dbo.OrderLineItems2012_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_04' and s.name = 'dbo') drop table dbo.OrderLineItems2012_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_05' and s.name = 'dbo') drop table dbo.OrderLineItems2012_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_06' and s.name = 'dbo') drop table dbo.OrderLineItems2012_06;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_07' and s.name = 'dbo') drop table dbo.OrderLineItems2012_07;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_08' and s.name = 'dbo') drop table dbo.OrderLineItems2012_08;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_09' and s.name = 'dbo') drop table dbo.OrderLineItems2012_09;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_10' and s.name = 'dbo') drop table dbo.OrderLineItems2012_10;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_11' and s.name = 'dbo') drop table dbo.OrderLineItems2012_11;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2012_12' and s.name = 'dbo') drop table dbo.OrderLineItems2012_12;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_01' and s.name = 'dbo') drop table dbo.OrderLineItems2013_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_02' and s.name = 'dbo') drop table dbo.OrderLineItems2013_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_03' and s.name = 'dbo') drop table dbo.OrderLineItems2013_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_04' and s.name = 'dbo') drop table dbo.OrderLineItems2013_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_05' and s.name = 'dbo') drop table dbo.OrderLineItems2013_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_06' and s.name = 'dbo') drop table dbo.OrderLineItems2013_06;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_07' and s.name = 'dbo') drop table dbo.OrderLineItems2013_07;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_08' and s.name = 'dbo') drop table dbo.OrderLineItems2013_08;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_09' and s.name = 'dbo') drop table dbo.OrderLineItems2013_09;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_10' and s.name = 'dbo') drop table dbo.OrderLineItems2013_10;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_11' and s.name = 'dbo') drop table dbo.OrderLineItems2013_11;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2013_12' and s.name = 'dbo') drop table dbo.OrderLineItems2013_12;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_01' and s.name = 'dbo') drop table dbo.OrderLineItems2014_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_02' and s.name = 'dbo') drop table dbo.OrderLineItems2014_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_03' and s.name = 'dbo') drop table dbo.OrderLineItems2014_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_04' and s.name = 'dbo') drop table dbo.OrderLineItems2014_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_05' and s.name = 'dbo') drop table dbo.OrderLineItems2014_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderLineItems2014_06' and s.name = 'dbo') drop table dbo.OrderLineItems2014_06;


if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_01' and s.name = 'dbo') drop table dbo.Orders2012_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_02' and s.name = 'dbo') drop table dbo.Orders2012_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_03' and s.name = 'dbo') drop table dbo.Orders2012_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_04' and s.name = 'dbo') drop table dbo.Orders2012_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_05' and s.name = 'dbo') drop table dbo.Orders2012_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_06' and s.name = 'dbo') drop table dbo.Orders2012_06;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_07' and s.name = 'dbo') drop table dbo.Orders2012_07;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_08' and s.name = 'dbo') drop table dbo.Orders2012_08;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_09' and s.name = 'dbo') drop table dbo.Orders2012_09;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_10' and s.name = 'dbo') drop table dbo.Orders2012_10;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_11' and s.name = 'dbo') drop table dbo.Orders2012_11;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2012_12' and s.name = 'dbo') drop table dbo.Orders2012_12;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_01' and s.name = 'dbo') drop table dbo.Orders2013_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_02' and s.name = 'dbo') drop table dbo.Orders2013_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_03' and s.name = 'dbo') drop table dbo.Orders2013_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_04' and s.name = 'dbo') drop table dbo.Orders2013_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_05' and s.name = 'dbo') drop table dbo.Orders2013_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_06' and s.name = 'dbo') drop table dbo.Orders2013_06;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_07' and s.name = 'dbo') drop table dbo.Orders2013_07;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_08' and s.name = 'dbo') drop table dbo.Orders2013_08;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_09' and s.name = 'dbo') drop table dbo.Orders2013_09;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_10' and s.name = 'dbo') drop table dbo.Orders2013_10;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_11' and s.name = 'dbo') drop table dbo.Orders2013_11;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2013_12' and s.name = 'dbo') drop table dbo.Orders2013_12;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_01' and s.name = 'dbo') drop table dbo.Orders2014_01;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_02' and s.name = 'dbo') drop table dbo.Orders2014_02;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_03' and s.name = 'dbo') drop table dbo.Orders2014_03;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_04' and s.name = 'dbo') drop table dbo.Orders2014_04;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_05' and s.name = 'dbo') drop table dbo.Orders2014_05;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders2014_06' and s.name = 'dbo') drop table dbo.Orders2014_06;
go

create table dbo.Orders2012_01
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_01
	primary key clustered(OrderId),
	--with (data_compression=page),

	constraint CHK_Orders2012_01
	check (OrderDate >= '2012-01-01' and OrderDate < '2012-02-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_01_CustomerId
on dbo.Orders2012_01(CustomerId) 
on [FG2012];

create table dbo.Orders2012_02
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_02
	primary key clustered(OrderId),

	constraint CHK_Orders2012_02
	check (OrderDate >= '2012-02-01' and OrderDate < '2012-03-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_02_CustomerId
on dbo.Orders2012_02(CustomerId) 
on [FG2012];


create table dbo.Orders2012_03
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_03
	primary key clustered(OrderId),

	constraint CHK_Orders2012_03
	check (OrderDate >= '2012-03-01' and OrderDate < '2012-04-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_03_CustomerId
on dbo.Orders2012_03(CustomerId) 
on [FG2012];

create table dbo.Orders2012_04
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_04
	primary key clustered(OrderId),

	constraint CHK_Orders2012_04
	check (OrderDate >= '2012-04-01' and OrderDate < '2012-05-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_04_CustomerId
on dbo.Orders2012_04(CustomerId) 
on [FG2012];

create table dbo.Orders2012_05
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_05
	primary key clustered(OrderId),

	constraint CHK_Orders2012_05
	check (OrderDate >= '2012-05-01' and OrderDate < '2012-06-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_05_CustomerId
on dbo.Orders2012_05(CustomerId) 
on [FG2012];


create table dbo.Orders2012_06
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_06
	primary key clustered(OrderId),

	constraint CHK_Orders2012_06
	check (OrderDate >= '2012-06-01' and OrderDate < '2012-07-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_06_CustomerId
on dbo.Orders2012_06(CustomerId) 
on [FG2012];

create table dbo.Orders2012_07
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_07
	primary key clustered(OrderId),

	constraint CHK_Orders2012_07
	check (OrderDate >= '2012-07-01' and OrderDate < '2012-08-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_07_CustomerId
on dbo.Orders2012_06(CustomerId) 
on [FG2012];

create table dbo.Orders2012_08
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_08
	primary key clustered(OrderId),

	constraint CHK_Orders2012_08
	check (OrderDate >= '2012-08-01' and OrderDate < '2012-09-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_08_CustomerId
on dbo.Orders2012_08(CustomerId) 
on [FG2012];

create table dbo.Orders2012_09
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_09
	primary key clustered(OrderId),

	constraint CHK_Orders2012_09
	check (OrderDate >= '2012-09-01' and OrderDate < '2012-10-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_09_CustomerId
on dbo.Orders2012_09(CustomerId) 
on [FG2012];

create table dbo.Orders2012_10
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_10
	primary key clustered(OrderId),

	constraint CHK_Orders2012_10
	check (OrderDate >= '2012-10-01' and OrderDate < '2012-11-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_10_CustomerId
on dbo.Orders2012_10(CustomerId) 
on [FG2012];

create table dbo.Orders2012_11
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_11
	primary key clustered(OrderId),

	constraint CHK_Orders2012_11
	check (OrderDate >= '2012-11-01' and OrderDate < '2012-12-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_11_CustomerId
on dbo.Orders2012_11(CustomerId) 
on [FG2012];

create table dbo.Orders2012_12
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2012_12
	primary key clustered(OrderId),

	constraint CHK_Orders2012_12
	check (OrderDate >= '2012-12-01' and OrderDate < '2013-01-01')
) on [FG2012];

create nonclustered index IDX_Orders2012_12_CustomerId
on dbo.Orders2012_12(CustomerId) 
on [FG2012];


create table dbo.Orders2013_01
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_01
	primary key clustered(OrderId),

	constraint CHK_Orders2013_01
	check (OrderDate >= '2013-01-01' and OrderDate < '2013-02-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_01_CustomerId
on dbo.Orders2013_01(CustomerId) 
on [FG2013];

create table dbo.Orders2013_02
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_02
	primary key clustered(OrderId),

	constraint CHK_Orders2013_02
	check (OrderDate >= '2013-02-01' and OrderDate < '2013-03-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_02_CustomerId
on dbo.Orders2013_02(CustomerId) 
on [FG2013];


create table dbo.Orders2013_03
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_03
	primary key clustered(OrderId),

	constraint CHK_Orders2013_03
	check (OrderDate >= '2013-03-01' and OrderDate < '2013-04-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_03_CustomerId
on dbo.Orders2013_03(CustomerId) 
on [FG2013];

create table dbo.Orders2013_04
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_04
	primary key clustered(OrderId),

	constraint CHK_Orders2013_04
	check (OrderDate >= '2013-04-01' and OrderDate < '2013-05-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_04_CustomerId
on dbo.Orders2013_04(CustomerId) 
on [FG2013];

create table dbo.Orders2013_05
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_05
	primary key clustered(OrderId),

	constraint CHK_Orders2013_05
	check (OrderDate >= '2013-05-01' and OrderDate < '2013-06-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_05_CustomerId
on dbo.Orders2013_05(CustomerId) 
on [FG2013];


create table dbo.Orders2013_06
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_06
	primary key clustered(OrderId),

	constraint CHK_Orders2013_06
	check (OrderDate >= '2013-06-01' and OrderDate < '2013-07-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_06_CustomerId
on dbo.Orders2013_06(CustomerId) 
on [FG2013];

create table dbo.Orders2013_07
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_07
	primary key clustered(OrderId),

	constraint CHK_Orders2013_07
	check (OrderDate >= '2013-07-01' and OrderDate < '2013-08-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_07_CustomerId
on dbo.Orders2013_06(CustomerId) 
on [FG2013];

create table dbo.Orders2013_08
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_08
	primary key clustered(OrderId),

	constraint CHK_Orders2013_08
	check (OrderDate >= '2013-08-01' and OrderDate < '2013-09-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_08_CustomerId
on dbo.Orders2013_08(CustomerId) 
on [FG2013];

create table dbo.Orders2013_09
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_09
	primary key clustered(OrderId),

	constraint CHK_Orders2013_09
	check (OrderDate >= '2013-09-01' and OrderDate < '2013-10-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_09_CustomerId
on dbo.Orders2013_09(CustomerId) 
on [FG2013];

create table dbo.Orders2013_10
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_10
	primary key clustered(OrderId),

	constraint CHK_Orders2013_10
	check (OrderDate >= '2013-10-01' and OrderDate < '2013-11-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_10_CustomerId
on dbo.Orders2013_10(CustomerId) 
on [FG2013];

create table dbo.Orders2013_11
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_11
	primary key clustered(OrderId),

	constraint CHK_Orders2013_11
	check (OrderDate >= '2013-11-01' and OrderDate < '2013-12-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_11_CustomerId
on dbo.Orders2013_11(CustomerId) 
on [FG2013];

create table dbo.Orders2013_12
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_Orders2013_12
	primary key clustered(OrderId),

	constraint CHK_Orders2013_12
	check (OrderDate >= '2013-12-01' and OrderDate < '2014-01-01')
) on [FG2013];

create nonclustered index IDX_Orders2013_12_CustomerId
on dbo.Orders2013_12(CustomerId) 
on [FG2013];


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
) on [FASTSTORAGE];

create nonclustered index IDX_Orders2014_04_CustomerId
on dbo.Orders2014_05(CustomerId) 
on [FASTSTORAGE]
go

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
) on [FASTSTORAGE];

create nonclustered index IDX_Orders2014_04_CustomerId
on dbo.Orders2014_06(CustomerId) 
on [FASTSTORAGE]
go

create view dbo.Orders(OrderId, OrderDate, OrderNum
	,OrderTotal, CustomerId /*Other Columns*/)
with schemabinding
as
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_01
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_02
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_03
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_04
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_05
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_06
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_07
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_08
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_09
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_10
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_11
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2012_12
					
	/* union all -- Other tables */
	union all

	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_01
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_02
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_03
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_04
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_05
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_06
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_07
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_08
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_09
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_10
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_11
	
	union all
	
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.Orders2013_12    
	
	union all

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
go



create table dbo.OrderLineItems2012_01
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_01
	check (OrderDate >= '2012-01-01' and OrderDate < '2012-02-01'),

	constraint FK_OrderLineItems_Orders_2012_01
	foreign key(OrderId)
	references dbo.Orders2012_01(OrderId),
);

create unique clustered index IDX_Orders2012_01_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_01(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_01_ArticleId
on dbo.OrderLineItems2012_01(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2012_02
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_02
	check (OrderDate >= '2012-02-01' and OrderDate < '2012-03-01'),

	constraint FK_OrderLineItems_Orders_2012_02
	foreign key(OrderId)
	references dbo.Orders2012_02(OrderId),
);

create unique clustered index IDX_Orders2012_02_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_02(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_02_ArticleId
on dbo.OrderLineItems2012_02(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2012_03
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_03
	check (OrderDate >= '2012-03-01' and OrderDate < '2012-04-01'),

	constraint FK_OrderLineItems_Orders_2012_03
	foreign key(OrderId)
	references dbo.Orders2012_03(OrderId),
);

create unique clustered index IDX_Orders2012_03_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_03(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_03_ArticleId
on dbo.OrderLineItems2012_03(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2012_04
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_04
	check (OrderDate >= '2012-04-01' and OrderDate < '2012-05-01'),

	constraint FK_OrderLineItems_Orders_2012_04
	foreign key(OrderId)
	references dbo.Orders2012_04(OrderId),
);

create unique clustered index IDX_Orders2012_04_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_04(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_04_ArticleId
on dbo.OrderLineItems2012_04(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2012_05
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_05
	check (OrderDate >= '2012-05-01' and OrderDate < '2012-06-01'),

	constraint FK_OrderLineItems_Orders_2012_05
	foreign key(OrderId)
	references dbo.Orders2012_05(OrderId),
);

create unique clustered index IDX_Orders2012_05_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_05(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_05_ArticleId
on dbo.OrderLineItems2012_05(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2012_06
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_06
	check (OrderDate >= '2012-06-01' and OrderDate < '2012-07-01'),

	constraint FK_OrderLineItems_Orders_2012_06
	foreign key(OrderId)
	references dbo.Orders2012_06(OrderId),
);

create unique clustered index IDX_Orders2012_06_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_06(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_06_ArticleId
on dbo.OrderLineItems2012_06(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2012_07
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_07
	check (OrderDate >= '2012-07-01' and OrderDate < '2012-08-01'),

	constraint FK_OrderLineItems_Orders_2012_07
	foreign key(OrderId)
	references dbo.Orders2012_07(OrderId),
);

create unique clustered index IDX_Orders2012_07_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_07(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_07_ArticleId
on dbo.OrderLineItems2012_07(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2012_08
(
	OrderId int not null,

	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_08
	check (OrderDate >= '2012-08-01' and OrderDate < '2012-09-01'),

	constraint FK_OrderLineItems_Orders_2012_08
	foreign key(OrderId)
	references dbo.Orders2012_08(OrderId),
);

create unique clustered index IDX_Orders2012_08_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_08(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_08_ArticleId
on dbo.OrderLineItems2012_08(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2012_09
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_09
	check (OrderDate >= '2012-09-01' and OrderDate < '2012-10-01'),

	constraint FK_OrderLineItems_Orders_2012_09
	foreign key(OrderId)
	references dbo.Orders2012_09(OrderId),
);

create unique clustered index IDX_Orders2012_09_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_09(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_09_ArticleId
on dbo.OrderLineItems2012_09(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2012_10
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_10
	check (OrderDate >= '2012-10-01' and OrderDate < '2012-11-01'),

	constraint FK_OrderLineItems_Orders_2012_10
	foreign key(OrderId)
	references dbo.Orders2012_10(OrderId),
);

create unique clustered index IDX_Orders2012_10_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_10(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_10_ArticleId
on dbo.OrderLineItems2012_10(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2012_11
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_11
	check (OrderDate >= '2012-11-01' and OrderDate < '2012-12-01'),

	constraint FK_OrderLineItems_Orders_2012_11
	foreign key(OrderId)
	references dbo.Orders2012_11(OrderId),
);

create unique clustered index IDX_Orders2012_11_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_11(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_11_ArticleId
on dbo.OrderLineItems2012_11(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2012_12
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2012_12
	check (OrderDate >= '2012-12-01' and OrderDate < '2013-01-01'),

	constraint FK_OrderLineItems_Orders_2012_12
	foreign key(OrderId)
	references dbo.Orders2012_12(OrderId),
);

create unique clustered index IDX_Orders2012_12_OrderId_OrderLineItemId
on dbo.OrderLineItems2012_12(OrderId, OrderLineItemId) 
on [FG2012];

create nonclustered index IDX_Orders2012_12_ArticleId
on dbo.OrderLineItems2012_12(ArticleId) 
on [FG2012];

create table dbo.OrderLineItems2013_01
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_01
	check (OrderDate >= '2013-01-01' and OrderDate < '2013-02-01'),

	constraint FK_OrderLineItems_Orders_2013_01
	foreign key(OrderId)
	references dbo.Orders2013_01(OrderId),
);

create unique clustered index IDX_Orders2013_01_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_01(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_01_ArticleId
on dbo.OrderLineItems2013_01(ArticleId) 
on [FG2013];

create table dbo.OrderLineItems2013_02
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_02
	check (OrderDate >= '2013-02-01' and OrderDate < '2013-03-01'),

	constraint FK_OrderLineItems_Orders_2013_02
	foreign key(OrderId)
	references dbo.Orders2013_02(OrderId),
);

create unique clustered index IDX_Orders2013_02_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_02(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_02_ArticleId
on dbo.OrderLineItems2013_02(ArticleId) 
on [FG2013];

create table dbo.OrderLineItems2013_03
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_03
	check (OrderDate >= '2013-03-01' and OrderDate < '2013-04-01'),

	constraint FK_OrderLineItems_Orders_2013_03
	foreign key(OrderId)
	references dbo.Orders2013_03(OrderId),
);

create unique clustered index IDX_Orders2013_03_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_03(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_03_ArticleId
on dbo.OrderLineItems2013_03(ArticleId) 
on [FG2013];

create table dbo.OrderLineItems2013_04
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_04
	check (OrderDate >= '2013-04-01' and OrderDate < '2013-05-01'),

	constraint FK_OrderLineItems_Orders_2013_04
	foreign key(OrderId)
	references dbo.Orders2013_04(OrderId),
);

create unique clustered index IDX_Orders2013_04_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_04(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_04_ArticleId
on dbo.OrderLineItems2013_04(ArticleId) 
on [FG2013];

create table dbo.OrderLineItems2013_05
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_05
	check (OrderDate >= '2013-05-01' and OrderDate < '2013-06-01'),

	constraint FK_OrderLineItems_Orders_2013_05
	foreign key(OrderId)
	references dbo.Orders2013_05(OrderId),
);

create unique clustered index IDX_Orders2013_05_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_05(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_05_ArticleId
on dbo.OrderLineItems2013_05(ArticleId) 
on [FG2013];

create table dbo.OrderLineItems2013_06
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_06
	check (OrderDate >= '2013-06-01' and OrderDate < '2013-07-01'),

	constraint FK_OrderLineItems_Orders_2013_06
	foreign key(OrderId)
	references dbo.Orders2013_06(OrderId),
);

create unique clustered index IDX_Orders2013_06_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_06(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_06_ArticleId
on dbo.OrderLineItems2013_06(ArticleId) 
on [FG2013];

create table dbo.OrderLineItems2013_07
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_07
	check (OrderDate >= '2013-07-01' and OrderDate < '2013-08-01'),

	constraint FK_OrderLineItems_Orders_2013_07
	foreign key(OrderId)
	references dbo.Orders2013_07(OrderId),
);

create unique clustered index IDX_Orders2013_07_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_07(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_07_ArticleId
on dbo.OrderLineItems2013_07(ArticleId) 
on [FG2013];

create table dbo.OrderLineItems2013_08
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_08
	check (OrderDate >= '2013-08-01' and OrderDate < '2013-09-01'),

	constraint FK_OrderLineItems_Orders_2013_08
	foreign key(OrderId)
	references dbo.Orders2013_08(OrderId),
);

create unique clustered index IDX_Orders2013_08_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_08(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_08_ArticleId
on dbo.OrderLineItems2013_08(ArticleId) 
on [FG2013];

create table dbo.OrderLineItems2013_09
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_09
	check (OrderDate >= '2013-09-01' and OrderDate < '2013-10-01'),

	constraint FK_OrderLineItems_Orders_2013_09
	foreign key(OrderId)
	references dbo.Orders2013_09(OrderId),
);

create unique clustered index IDX_Orders2013_09_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_09(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_09_ArticleId
on dbo.OrderLineItems2013_09(ArticleId) 
on [FG2013];

create table dbo.OrderLineItems2013_10
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_10
	check (OrderDate >= '2013-10-01' and OrderDate < '2013-11-01'),

	constraint FK_OrderLineItems_Orders_2013_10
	foreign key(OrderId)
	references dbo.Orders2013_10(OrderId),
);

create unique clustered index IDX_Orders2013_10_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_10(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_10_ArticleId
on dbo.OrderLineItems2013_10(ArticleId) 
on [FG2013];

create table dbo.OrderLineItems2013_11
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_11
	check (OrderDate >= '2013-11-01' and OrderDate < '2013-12-01'),

	constraint FK_OrderLineItems_Orders_2013_11
	foreign key(OrderId)
	references dbo.Orders2013_11(OrderId),
);

create unique clustered index IDX_Orders2013_11_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_11(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_11_ArticleId
on dbo.OrderLineItems2013_11(ArticleId) 
on [FG2013];

create table dbo.OrderLineItems2013_12
(
	OrderId int not null,
	OrderLineItemId int not null,
	OrderDate datetime not null,
	ArticleId int not null,
	Quantity decimal(9,3) not null,
	Price money not null,
	/* Other Columns */
	constraint CHK_OrderLineItems2013_12
	check (OrderDate >= '2013-12-01' and OrderDate < '2014-01-01'),

	constraint FK_OrderLineItems_Orders_2013_12
	foreign key(OrderId)
	references dbo.Orders2013_12(OrderId),
);

create unique clustered index IDX_Orders2013_12_OrderId_OrderLineItemId
on dbo.OrderLineItems2013_12(OrderId, OrderLineItemId) 
on [FG2013];

create nonclustered index IDX_Orders2013_12_ArticleId
on dbo.OrderLineItems2013_12(ArticleId) 
on [FG2013];

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
on [FG2014]
go

create view dbo.OrderLineItems(OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price)
with schemabinding 
as
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_01
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_02
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_03
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_04
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_05
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_06
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_07
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_08
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_09
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_10
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_11
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2012_12
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_01
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_02
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_03
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_04
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_05
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_06
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_07
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_08
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_09
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_10
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_11
	union all
	select OrderId, OrderLineItemId, OrderDate, ArticleId, Quantity, Price
	from dbo.OrderLineItems2013_12
	union all
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
go


/*** Querying Partitioned View ***/
-- Enable "Include Actual Execution Plan"
select count(*) from dbo.Orders;
select count(*) from dbo.Orders where OrderDate = '2014-06-03'
go


select o.OrderId, o.OrderNum, o.OrderDate, i.Quantity, i.Price
from dbo.Orders o join dbo.OrderLineItems i on
	o.OrderId = i.OrderId
where 
	o.OrderDate >= '2014-01-01' and
	o.OrderDate < '2014-02-01' and
	o.CustomerId = 1 and
	i.ArticleId = 2;

select o.OrderId, o.OrderNum, o.OrderDate, i.Quantity, i.Price
from dbo.Orders o join dbo.OrderLineItems i on
	o.OrderId = i.OrderId and
	o.OrderDate = i.OrderDate
where 
	o.OrderDate >= '2014-01-01' and
	o.OrderDate < '2014-02-01' and
	o.CustomerId = 1 and
	i.ArticleId = 2

