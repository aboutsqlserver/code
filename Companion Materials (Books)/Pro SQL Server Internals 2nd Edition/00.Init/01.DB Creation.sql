/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Database Creation Script                           */
/****************************************************************************/

set noexec off
go

use master
go

if exists
(
	select * from sys.databases where name = 'SQLServerInternals'
)
begin
	raiserror('Database SQLServerInternals already exists',16,1)
	set noexec on
end
go


declare
	@version int
	,@dataPath nvarchar(512)
	,@logPath nvarchar(512) 

set @version = 
	convert(int,
		left(
			convert(nvarchar(128), serverproperty('ProductVersion')),
			charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
		)
	)

if @version >= 11 -- SQL Server 2014+
begin
	select 
		@dataPath = convert(nvarchar(512),serverproperty('InstanceDefaultDataPath'))
		,@logPath = convert(nvarchar(512),serverproperty('InstanceDefaultLogPath'))
end
else begin
	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @dataPath output
	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @logPath output
end

-- Creating database in the same folder with master
if @dataPath is null
	select @dataPath = substring(physical_name, 1, len(physical_name) - charindex('\', reverse(physical_name))) + '\'
	from master.sys.database_files 
	where file_id = 1

if @logPath is null
	select @logPath = substring(physical_name, 1, len(physical_name) - charindex('\', reverse(physical_name))) + '\'
	from master.sys.database_files 
	where file_id = 2
	
if @dataPath is null or @logPath is null
begin
	raiserror('Cannot obtain path for data and/or log file',16,1)
	set noexec on
end

if right(@dataPath, 1) <> '\'
	select @dataPath = @dataPath + '\'
if right(@logPath, 1) <> '\'
	select @logPath = @logPath + '\'
	
declare
	@SQL nvarchar(max)

select @SQL = 
	replace
	(
		replace(
N'create database [SQLServerInternals]
on primary (name=N''SQLServerInternals'', filename=N''%DATA%SqlServerInternals.mdf'', size=10MB, filegrowth = 10MB),
filegroup [FASTSTORAGE] (name=N''SqlServerInternals_FAST'', filename=N''%DATA%SqlServerInternals_FAST.ndf'', size=100MB, filegrowth = 100MB), 
filegroup [FG2014] (name=N''SqlServerInternals_2014'', filename=N''%DATA%SqlServerInternals_2014.ndf'', size=100MB, filegrowth = 100MB),
filegroup [FG2015] (name=N''SqlServerInternals_2015'', filename=N''%DATA%SqlServerInternals_2015.ndf'', size=100MB, filegrowth = 100MB),
filegroup [FG2016] (name=N''SqlServerInternals_2016'', filename=N''%DATA%SqlServerInternals_2016.ndf'', size=100MB, filegrowth = 100MB)
log on (name=N''SQLServerInternals_log'', filename=N''%LOG%SqlServerInternals.ldf'', size=256MB, filegrowth = 256MB);

alter database [SQLServerInternals] set recovery simple;
alter database [SQLServerInternals] modify filegroup [FASTSTORAGE] default;

'
			,'%DATA%',@dataPath
		),'%LOG%',@logPath
	)

raiserror('Creating database SQLServerInternals',0,1) with nowait
raiserror('Data Path: %s',0,1,@dataPath) with nowait
raiserror('Log Path: %s',0,1,@logPath) with nowait
raiserror('Statement:',0,1) with nowait
raiserror(@sql,0,1) with nowait

exec sp_executesql @sql
go

/* Creating the objects for Part 3 "Locking and Blocking" */
use SQLServerInternals
go

exec sp_executesql N'create schema [Delivery]'
go

create table Delivery.Orders
(
	OrderId int not null identity(1,1),
	OrderDate smalldatetime not null, 
	OrderNum varchar(20) not null,
	Reference varchar(64) null,
	CustomerId int not null,
	PickupAddressId int not null,
	DeliveryAddressId int not null,
	ServiceId int not null,
	RatePlanId int not null,
	OrderStatusId int not null,
	DriverId int null,
	Pieces smallint not null,
	Amount smallmoney not null,
	ModTime datetime not null
		constraint DEF_Orders_ModTime
		default getDate(),
	PlaceHolder char(100) not null
		constraint DEF_Orders_Placeholder
		default 'Placeholder',
		
	constraint PK_Orders
	primary key clustered(OrderId)
)
go

declare
	@MaxOrderId int
	,@MaxCustomers int
	,@MaxAddresses int
	,@MaxDrivers int

select 
	@MaxOrderId=65536, @MaxCustomers=1000
	,@MaxAddresses=20, @MaxDrivers = 125

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
--,N6(C) as (select 0 from N5 as T1 cross join N3 as T2) -- 1,048,576 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N5)
,Info(OrderId, CustomerId, OrderDateOffset, RateplanId, ServiceId, Pieces)
as
(
	select 
		ID, ID % @MaxCustomers + 1, ID % (365*24*60)
		,ID % 2 + 1, Id % 3 + 1, ID % 5 + 1
	from IDs 
	where ID <= @MaxOrderId
)
,Info2(OrderId, OrderDate, OrderNum, CustomerId, RateplanId ,ServiceId
	,Pieces ,PickupAddressId, OrderStatusId, Rate)
as
(
	select 
		OrderId, dateadd(minute, -OrderDateOffset, getdate())
		,convert(varchar(10),OrderId), CustomerId
		,RatePlanId, ServiceId, Pieces
		,(CustomerId - 1) * @MaxAddresses + OrderId % 20
		,case	
			when OrderDateOffset > 5 * 24 * 60
			then 4
			else OrderId % 4 + 1
		end, (OrderID % 5 + 1) * 10.
	from Info
)	
insert into Delivery.Orders(OrderDate, OrderNum, CustomerId,
	PickupAddressId, DeliveryAddressId, ServiceId, RatePlanId,
	OrderStatusId, DriverId, Pieces, Amount)
select 
	o.OrderDate, o.OrderNum, o.CustomerId, o.PickupAddressID
	,case 
		when o.PickupAddressID % @MaxAddresses = 0
		then o.PickupAddressID + 1
		else o.PickupAddressID - 1
	end, o.ServiceID, o.RateplanId, o.OrderStatusId
	,case
		when o.OrderStatusId in (1,4)
		then NULL
		else OrderId % @MaxDrivers + 1
	end, o.Pieces, o.Rate
from Info2 o;

