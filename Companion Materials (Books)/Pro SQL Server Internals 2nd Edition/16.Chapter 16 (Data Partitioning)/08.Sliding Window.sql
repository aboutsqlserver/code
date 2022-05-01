/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 16. Data Partitioning                       */
/*                          Sliding Window Pattern                          */
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


if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'SlidingWindowTmp' and s.name = 'dbo') drop table dbo.SlidingWindowTmp;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'SlidingWindow' and s.name = 'dbo') drop table dbo.SlidingWindow;
if exists(select * from sys.partition_schemes where name = 'psSlidingWindow') drop partition scheme psSlidingWindow;
if exists(select * from sys.partition_functions where name = 'pfSlidingWindow') drop partition function pfSlidingWindow;
go

create partition function pfSlidingWindow(datetime)
as range right for values 
('2015-07-01','2015-08-01','2015-09-01','2015-10-01'
,'2015-11-01','2015-12-01','2016-01-01','2016-02-01'
,'2016-03-01','2016-04-01','2016-05-01','2016-06-01'
,'2016-07-01','2016-08-01' /* One extra empty partition */
);

create partition scheme psSlidingWindow 
as partition pfSlidingWindow
all to ([FG2016]);
go

create table dbo.SlidingWindow
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
);

create unique clustered index IDX_SlidingWindow_OrderDate_OrderId
on dbo.SlidingWindow(OrderDate, OrderId) 
on psSlidingWindow(OrderDate);

create nonclustered index IDX_SlidingWindow_CustomerId
on dbo.SlidingWindow(CustomerId) 
on psSlidingWindow(OrderDate);
go

create table dbo.SlidingWindowTmp
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
);

create unique clustered index IDX_SlidingWindowTmp_OrderDate_OrderId
on dbo.SlidingWindowTmp(OrderDate, OrderId) 
on [FG2016];

create nonclustered index IDX_SlidingWindowTmp_CustomerId
on dbo.SlidingWindowTmp(CustomerId) 
on [FG2016];
go

-- Purging old partition
alter table dbo.SlidingWindow switch partition 1 to dbo.SlidingWindowTmp;
truncate table dbo.SlidingWindowTmp;
go

-- Creating new partition
alter partition scheme psSlidingWindow next used [FG2016];
alter partition function pfSlidingWindow() split range('2016-09-01');
go
