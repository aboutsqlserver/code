/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 16. Data Partitioning                       */
/*                        Creating Partitioned Table                        */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'OrdersPT') drop table dbo.OrdersPT;
if exists(select * from sys.partition_schemes where name = 'psOrders') drop partition scheme psOrders;
if exists(select * from sys.partition_functions where name = 'pfOrders') drop partition function pfOrders;
go

create partition function pfOrders(datetime)
as range right for values 
('2014-02-01', '2014-03-01','2014-04-01','2014-05-01','2014-06-01','2014-07-01'
,'2014-08-01','2014-09-01','2014-10-01','2014-11-01','2014-12-01','2015-01-01'
,'2015-02-01','2015-03-01','2015-04-01','2015-05-01','2015-06-01','2015-07-01'
,'2015-08-01','2015-09-01','2015-10-01','2015-11-01','2015-12-01','2016-01-01'
,'2016-02-01','2016-03-01','2016-04-01','2016-05-01','2016-06-01','2016-07-01');
go

create partition scheme psOrders 
as partition pfOrders
to (FG2014 /* FileGroup to store data <'2014-02-01' */
,FG2014 /* FileGroup to store data >='2014-02-01' and <'2014-03-01' */
,FG2014,FG2014,FG2014,FG2014,FG2014
,FG2014,FG2014,FG2014,FG2014,FG2014
,FG2015 /* FileGroup to store data >='2015-01-01' and <'2015-02-01' */
,FG2015,FG2015,FG2015,FG2015,FG2015
,FG2015,FG2015,FG2015,FG2015,FG2015,FG2015
,FG2016 /* FileGroup to store data >='2016-01-01' and <'2016-02-01' */
,FG2016,FG2016,FG2016
,FASTSTORAGE /* FileGroup to store data >='2016-05-01' and <'2016-06-01' */
,FASTSTORAGE /* FileGroup to store data >='2016-06-01' and <'2016-07-01' */
,FASTSTORAGE /* FileGroup to store data >='2016-07-01' */ );
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

