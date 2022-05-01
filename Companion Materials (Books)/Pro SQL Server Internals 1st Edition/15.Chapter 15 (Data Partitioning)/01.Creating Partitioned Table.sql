/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                      Chapter 15. Data Partitioning                       */
/*                        Creating Partitioned Table                        */
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
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'OrdersPT' and s.name = 'dbo'
)
	drop table dbo.OrdersPT
go

if exists(
	select *
	from sys.partition_schemes 
	where name = 'psOrders'
)
	drop partition scheme psOrders
go


if exists(
	select *
	from sys.partition_functions
	where name = 'pfOrders'
)
	drop partition function pfOrders
go

create partition function pfOrders(datetime)
as range right for values 
('2012-02-01', '2012-03-01','2012-04-01','2012-05-01','2012-06-01'
,'2012-07-01','2012-08-01','2012-09-01','2012-10-01','2012-11-01'
,'2012-12-01','2013-01-01','2013-02-01','2013-03-01','2013-04-01'
,'2013-05-01','2013-06-01','2013-07-01','2013-08-01','2013-09-01'
,'2013-10-01','2013-11-01','2013-12-01','2014-01-01','2014-02-01'
,'2014-03-01','2014-04-01','2014-05-01','2014-06-01','2014-07-01')
go


create partition scheme psOrders 
as partition pfOrders
to (
	FG2012 /* FileGroup to store data <'2012-02-01' */
	,FG2012 /* FileGroup to store data >='2012-02-01' and <'2012-03-01' */
	,FG2012,FG2012,FG2012,FG2012,FG2012
	,FG2012,FG2012,FG2012,FG2012,FG2012
	,FG2013 /* FileGroup to store data >='2013-01-01' and <'2013-02-01' */
	,FG2013,FG2013,FG2013,FG2013,FG2013
	,FG2013,FG2013,FG2013,FG2013,FG2013,FG2013
	,FG2014 /* FileGroup to store data >='2014-01-01' and <'2014-02-01' */
	,FG2014,FG2014,FG2014
	,FASTSTORAGE /* FileGroup to store data >='2014-05-01' and <'2014-06-01' */
	,FASTSTORAGE /* FileGroup to store data >='2014-06-01' and <'2014-07-01' */
	,FASTSTORAGE /* FileGroup to store data >='2014-07-01' */
)
go

create table dbo.OrdersPT
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
)
go

create unique clustered index IDX_OrdersPT_OrderDate_OrderId
on dbo.OrdersPT(OrderDate, OrderId) 
/* You can enable Compression in SQL Server 2008+ 
with 
(
	data_compression = page on partitions(1 to 28),
	data_compression = none on partitions(29 to 31)
) */
on psOrders(OrderDate);

create nonclustered index IDX_OrdersPT_CustomerId
on dbo.OrdersPT(CustomerId) 
/* You can enable Compression in SQL Server 2008+ 
with 
(
	data_compression = page on partitions(1 to 28),
	data_compression = none on partitions(29 to 31)
) */
on psOrders(OrderDate);
go

