/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                      Chapter 15. Data Partitioning                       */
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
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'SlidingWindowTmp' and s.name = 'dbo'
)
	drop table dbo.SlidingWindowTmp
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'SlidingWindow' and s.name = 'dbo'
)
	drop table dbo.SlidingWindow
go

if exists(
	select *
	from sys.partition_schemes 
	where name = 'psSlidingWindow'
)
	drop partition scheme psSlidingWindow
go


if exists(
	select *
	from sys.partition_functions
	where name = 'pfSlidingWindow'
)
	drop partition function pfSlidingWindow
go

create partition function pfSlidingWindow(datetime)
as range right for values 
('2013-07-01','2013-08-01','2013-09-01','2013-10-01'
,'2013-11-01','2013-12-01','2014-01-01','2014-02-01'
,'2014-03-01','2014-04-01','2014-05-01','2014-06-01'
,'2014-07-01','2014-08-01' /* One extra empty partition */
);

create partition scheme psSlidingWindow 
as partition pfSlidingWindow
all to ([FG2014]);
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
on [FG2014];

create nonclustered index IDX_SlidingWindowTmp_CustomerId
on dbo.SlidingWindowTmp(CustomerId) 
on [FG2014];
go

-- Purging old partition
alter table dbo.SlidingWindow switch partition 1 to dbo.SlidingWindowTmp;
truncate table dbo.SlidingWindowTmp;
go

-- Creating new partition
alter partition scheme psSlidingWindow next used [FG2014];
alter partition function pfSlidingWindow() split range('2014-09-01')
go
