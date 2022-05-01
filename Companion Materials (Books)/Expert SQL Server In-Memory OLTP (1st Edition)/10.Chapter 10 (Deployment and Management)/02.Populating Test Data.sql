/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 10: Deployment and Management                    */
/*                02.Populating Test Data for the Chapter                   */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if not exists (select * from sys.schemas where name = 'Delivery')
	exec sp_executesql N'create schema [Delivery]'
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertOrder' and s.name = 'Delivery') drop proc Delivery.InsertOrder;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'DeleteCustomer' and s.name = 'Delivery') drop proc Delivery.DeleteCustomer;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders' and s.name = 'Delivery') drop table Delivery.Orders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Customers' and s.name = 'Delivery') drop table Delivery.Customers;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Addresses' and s.name = 'Delivery') drop table Delivery.Addresses;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Services' and s.name = 'Delivery') drop table Delivery.Services;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'RatePlans' and s.name = 'Delivery') drop table Delivery.RatePlans;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Drivers' and s.name = 'Delivery') drop table Delivery.Drivers;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Rates' and s.name = 'Delivery') drop table Delivery.Rates;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OrderStatuses' and s.name = 'Delivery') drop table Delivery.OrderStatuses;
go


create table Delivery.Orders
(
	OrderId int not null identity(1,1)
		primary key nonclustered
        hash with (bucket_count=1000000),
	OrderDate smalldatetime not null, 
	OrderNum varchar(20) 
		collate Latin1_General_100_BIN2 not null,
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
		default sysutcdatetime(),
	PlaceHolder char(100) not null
		constraint DEF_Orders_Placeholder
		default 'Placeholder',
		
	index IDX_Orders_OrderNum
	nonclustered hash(OrderNum)
	with (bucket_count = 1000000),

	index IDX_Orders_CustomerId
	nonclustered hash(CustomerId)
	with (bucket_count = 1000000),
)
with (memory_optimized=on, durability=schema_only);
go

create proc Delivery.InsertOrder
(
	@OrderNum varchar(20)
	,@Reference varchar(64)
	,@CustomerId int 
	,@PickupAddressId int 
	,@DeliveryAddressId int 
	,@ServiceId int 
	,@RatePlanId int 
	,@OrderStatusId int 
	,@DriverId int
	,@Pieces smallint 
	,@Amount smallmoney 
)
with 
	native_compilation	
	,schemabinding
	,execute as owner	
as
begin atomic with
(
	transaction isolation level = snapshot
	,language = N'English'
)
	insert into Delivery.Orders(OrderNum,OrderDate,Reference,CustomerId
		,PickupAddressId,DeliveryAddressId,ServiceId
		,RatePlanId,OrderStatusId,DriverId,Pieces,Amount)
	values(@OrderNum,GetDate(),@Reference,@CustomerId
		,@PickupAddressId,@DeliveryAddressId,@ServiceId
		,@RatePlanId,@OrderStatusId,@DriverId,@Pieces,@Amount)
end
go


create table Delivery.Customers
(
	CustomerID int not null identity(1,1)
		primary key nonclustered
        hash with (bucket_count=100000),
	Name varchar(100) 
		collate Latin1_General_100_BIN2 not null,
	Phone varchar(20) not null,
	ContactName varchar(100) not null,
	BillingAddress varchar(100) not null,
	BillingCity varchar(40) not null,
	BillingState char(2) not null,
	BillingZip char(5) not null,
	DefaultRatePlan int null,
	DefaultService int null,
	RegionId int not null,

	index IDX_Customers
	nonclustered(Name)
)
with (memory_optimized=on, durability=schema_only);
go


create table Delivery.Addresses
(
	AddressId int not null identity(1,1)
		primary key nonclustered
        hash with (bucket_count=1000000),
	CustomerId int not null,
	Address varchar(100) not null,
	City varchar(40) not null,
	State char(2) not null,
	Zip char(5) not null,
	Direction varchar(1024) null,	
	
	index IDX_Addresses_CustomerId
	nonclustered hash(CustomerId)
	with (bucket_count = 100000)
)
with (memory_optimized=on, durability=schema_only);
go

create table Delivery.Services
(
	ServiceID int not null
		primary key nonclustered
        hash with (bucket_count=256),
	Name varchar(40) not null,
)
with (memory_optimized=on, durability=schema_only);
go

create table Delivery.RatePlans
(
	RatePlanID int not null
		primary key nonclustered
        hash with (bucket_count=256),
	Name varchar(40) not null,
)
with (memory_optimized=on, durability=schema_only);
go

create table Delivery.Rates
(
	RatePlanID int not null,
	ServiceId int not null,
	Rate smallmoney not null,

	primary key nonclustered
    hash (RatePlanId, ServiceId)
	with (bucket_count=1024),
)
with (memory_optimized=on, durability=schema_only);
go

create table Delivery.Drivers
(
	DriverId int not null identity(1,1)
		primary key nonclustered
        hash with (bucket_count=1024),
	Name varchar(40)
		collate Latin1_General_100_BIN2 not null,
	
	index IDX_Drivers_Name
	nonclustered(Name)
)
with (memory_optimized=on, durability=schema_only);
go

create table Delivery.OrderStatuses
(
	OrderStatusId int not null identity(1,1)
		primary key nonclustered
        hash with (bucket_count=1024),
	Name varchar(40) not null,
)
with (memory_optimized=on, durability=schema_only);
go

create proc Delivery.DeleteCustomer
(
	@CustomerId int
)
with 
	native_compilation	
	,schemabinding
	,execute as owner	
as
begin atomic with
(
	transaction isolation level = snapshot
	,language = N'English'
)
	delete from Delivery.Addresses where CustomerId = @CustomerId;
	delete from Delivery.Orders where CustomerId = @CustomerId;
	delete from Delivery.Customers where CustomerId = @CustomerId;
end
go

declare
	@MaxOrderId int
	,@MaxCustomers int
	,@MaxAddresses int
	,@MaxDrivers int

select 
	@MaxOrderId=65536 * 16, @MaxCustomers=25000
	,@MaxAddresses=20, @MaxDrivers = 125

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,N6(C) as (select 0 from N5 as T1 cross join N3 as T2) -- 1,048,576 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N6)
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
from Info2 o 	
go


begin tran
	insert into Delivery.OrderStatuses(Name)
		select 'NEW' union all 
		select 'DISPATCHED' union all
		select 'IN ROUTE' union all
		select 'COMPLETED'
		
	insert into Delivery.Services(ServiceID,Name)
		select 1, 'BASE' union all
		select 2, 'RUSH' union all
		select 3, '2-HOURS' 
		
	insert into Delivery.RatePlans(RatePlanID, Name)
		select 1, 'REGULAR' union all
		select 2, 'CORPORATE' 

	insert into Delivery.Rates(ServiceId, RatePlanID, Rate)
		select 1, 1, 15 union all select 1, 2, 10 union all
		select 2, 1, 25 union all select 2, 2, 20 union all
		select 3, 1, 35 union all select 3, 2, 30
		
	declare
		@CustomerId int
		,@AddressId int
		
	select @CustomerId = 1
	
	while @CustomerId <= 50000
	begin
		insert into Delivery.Customers(Name, Phone, ContactName, 
			BillingAddress, BillingCity, BillingState, BillingZip,
			DefaultRatePlan, DefaultService, RegionId)
		values('Customer # ' + convert(varchar(5), @CustomerId), '813-123-4567',
		'Contact for Customer # ' + convert(varchar(5), @CustomerId),'123 Main Street',
		'Tampa', 'FL','33607',@CustomerId % 3, 1, @CustomerId % 50)
		
		select @AddressId = 0
		while @AddressId < 5
		begin
			insert into Delivery.Addresses(CustomerId,Address,City,State,Zip,Direction)
			values(@CustomerId, '456 Main Street', 'Tampa', 'FL', '33607', REPLICATE(' ',200))
			
			select @AddressId = @AddressId + 1
		end
		select @CustomerId = @CustomerId + 1
	end

	declare
		@DriverId int
		
	select @DriverId = 1
	
	while @DriverId <= 100
	begin
		insert into Delivery.Drivers(Name)
		values('Driver # ' + convert(varchar(5), @DriverId))
		
		select @DriverId = @DriverId + 1
	end
commit
go
