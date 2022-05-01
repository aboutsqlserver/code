/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 05. SQL Server 2016 Feautes                    */
/*                 Dmitri Korotkevitch with Thomas Grohser                  */
/*                          Stretch Databases                               */
/****************************************************************************/

use SQLServerInternals
go

/*****************************************************************************
Enable Stretching for the database. You can use SSMS wizards or code below

exec sp_configure 'remote data archive' , '1';  
go
reconfigure
go

-- Enable Stretching on Database-Level
-- Creating the Master Key
create master key encryption by password='StrongPassw0rd';
go

-- Create Database Scoped Credentials with SQL Server Login Info
create database scoped credential AzureCredentials2
with 
	identity = 'dmitri'
	,secret = 'StrongPassw0rd';
go

-- 03. Alter 
alter database StatsUpdateTest
set remote_data_archive = on
(
	server = 'myserver.database.windows.net'
	,credential = AzureCredentials2
);
*****************************************************************************/

drop table if exists dbo.AppLogs;
drop table if exists dbo.Orders;
drop table if exists dbo.Customers;
drop function if exists dbo.fnOrdersOlderThanJan2016;
drop function if exists dbo.fnOrdersOlderThanFeb2016;
drop function if exists dbo.fnInvalid;
go

create table dbo.AppLogs
(
	OnDate datetime2(3) not null,
	ID bigint identity(1,1) not null,
	LogMsg varchar(max) not null

	constraint PK_AppLogs
	primary key nonclustered(ID)
);

create unique clustered index IDX_AppLogs
on dbo.AppLogs(OnDate,ID);
go

create table dbo.Customers
(
	CustomerId int identity(1,1) not null,
	Name nvarchar(32) not null,
	PostalCode char(5) not null,
	constraint PK_Customers
	primary key clustered(CustomerId)
)
go

;with N1(C) as (select 0 union all select 0) -- 2 rows    
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows    
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows    
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows    
,IDs(ID) as (select row_number() over (order by (select NULL)) from N4)    
insert into dbo.Customers(Name, PostalCode)            
	select 
		'Customer ' + convert(varchar(32),i1.ID * i2.Id)
		,convert(char(5),10000 + i2.ID)
	from 
		IDs i1 cross join IDs i2;
go


create table dbo.Orders
(
	OrderId int not null,
	CustomerID int not null,
	OrderDate datetime2(0) not null,
	Amount money not null,
	Completed bit not null,

	constraint PK_Orders
	primary key clustered(OrderId)
	with (data_compression=page)
);

declare
	@StartDate datetime2(0) = '2016-09-01';

with N1(C) as (select 0 union all select 0) -- 2 rows    
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows    
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows    
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows    
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows    
,N6(C) as (select 0 from N5 as T1 CROSS JOIN N3 as T2) -- 1,048,576 rows  
,IDs(ID) as (select row_number() over (order by (select NULL)) from N6) 
insert into dbo.Orders(OrderId, CustomerId, Amount, OrderDate, Completed)            
	select ID, ID % 65536 + 1, Id % 50, dateadd(day,-ID % 365, getDate()),0
	from IDs;
go

alter table dbo.AppLogs
set (remote_data_archive = on (migration_state = outbound));
go

create function dbo.fnOrdersOlderThanJan2016(@OrderDate datetime2(0))
returns table
with schemabinding
as
return
(
	select 1 as is_migrating
	where @OrderDate < convert(datetime2(0), '1/1/2016', 101)
)
go

alter table dbo.Orders
set
(
	remote_data_archive = on
	(
		filter_predicate = dbo.fnOrdersOlderThanJan2016(OrderDate),
		migration_state = outbound
	)
)
go

create function dbo.fnOrdersOlderThanFeb2016(@OrderDate datetime2(0))
returns table
with schemabinding
as
return
(
	select 1 as is_migrating
	where @OrderDate < convert(datetime2(0), '2/1/2016', 101)
)
go

alter table dbo.Orders
set
(
	remote_data_archive = on
	(
		filter_predicate = dbo.fnOrdersOlderThanFeb2016(OrderDate),
		migration_state = outbound
	)
)
go

create function dbo.fnInvalid(@OrderDate datetime2(0),@Completed bit)
returns table
with schemabinding
as
return
(
	select 1 as is_migrating
	where (@Completed = 1) and @OrderDate < convert(datetime2(0), '1/2/2016', 101)
)
go


select count(*) from dbo.Orders;
select count(*) from dbo.Orders where OrderDate < '2016-02-01'
select count(*) from dbo.Orders with (remote_data_archive_override = local_only);
select count(*) from dbo.Orders with (remote_data_archive_override = remote_only);
select count(*) from dbo.Orders with (remote_data_archive_override = stage_only);

-- Check Execution Plans
select c.Name, sum(o.Amount) as [Total Sales]
from dbo.Customers c join dbo.Orders o on
    c.CustomerId = o.CustomerId
group by c.Name;

select c.Name, sum(o.Amount) as [Total Sales]
from dbo.Customers c join dbo.Orders o on
    c.CustomerId = o.CustomerId
where c.PostalCode = '10050'
group by c.Name;