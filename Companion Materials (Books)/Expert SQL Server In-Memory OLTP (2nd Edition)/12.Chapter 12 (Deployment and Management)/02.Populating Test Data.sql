/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 12: Deployment and Management                    */
/*                02.Populating Test Data for the Chapter                   */
/****************************************************************************/

set nocount on
set xact_abort on
go

use InMemoryOLTP2016
go

if not exists (select * from sys.schemas where name = 'Delivery')
	exec sp_executesql N'create schema [Delivery]'
go

drop proc if exists Delivery.InsertOrder;
drop proc if exists Delivery.DeleteCustomer;
drop table if exists Delivery.Orders;
drop table if exists Delivery.Addresses;
drop table if exists Delivery.Services;
drop table if exists Delivery.RatePlans;
drop table if exists Delivery.Drivers;
drop table if exists Delivery.Rates;
drop table if exists Delivery.OrderStatuses;
drop table if exists Delivery.Customers;
go

create table Delivery.Customers
(
	CustomerId int not null Identity(1,1)
		constraint PK_Customers
		primary key nonclustered
        hash with (bucket_count=524288),
	Name varchar(100) not null,
	Phone varchar(20) not null,
	ContactName varchar(100) not null,
	BillingAddress varchar(100) not null,
	BillingCity varchar(40) not null,
	BillingState char(2) not null,
	BillingZip char(5) not null,
	DefaultRatePlan int null,
	DefaultService int null,
	RegionId int not null,

	index IdX_Customers	nonclustered(Name)
)
with (memory_optimized=on, durability=schema_only);
go

create table Delivery.Addresses
(
	AddressId int not null Identity(1,1)
		constraint PK_Addresses
		primary key nonclustered
        hash with (bucket_count=1048576),
	CustomerId int not null,
	Address varchar(100) not null,
	City varchar(40) not null,
	State char(2) not null,
	Zip char(5) not null,
	Direction varchar(1024) null,	
	
	index IdX_Addresses_CustomerId
	nonclustered hash(CustomerId)
	with (bucket_count = 524288),

	constraint FK_Addresses_Customers
	foreign key(CustomerId)
	references Delivery.Customers(CustomerId)
)
with (memory_optimized=on, durability=schema_only);
go

create table Delivery.Services
(
	ServiceId int not null
		constraint PK_Services
		primary key nonclustered
        hash with (bucket_count=256),
	Name varchar(40) not null,
)
with (memory_optimized=on, durability=schema_only);
go

create table Delivery.RatePlans
(
	RatePlanId int not null
		constraint PK_RatePlans
		primary key nonclustered
        hash with (bucket_count=256),
	Name varchar(40) not null,
)
with (memory_optimized=on, durability=schema_only);
go

create table Delivery.Rates
(
	RatePlanId int not null,
	ServiceId int not null,
	Rate smallmoney not null,

	constraint PK_Rates
	primary key nonclustered
    hash (RatePlanId, ServiceId)
	with (bucket_count=1024),
)
with (memory_optimized=on, durability=schema_only);
go

create table Delivery.Drivers
(
	DriverId int not null Identity(1,1)
		constraint PK_Drivers
		primary key nonclustered
        hash with (bucket_count=1024),
	Name varchar(40) not null,
	
	index IdX_Drivers_Name
	nonclustered(Name)
)
with (memory_optimized=on, durability=schema_only);
go

create table Delivery.OrderStatuses
(
	OrderStatusId int not null Identity(1,1)
		constraint PK_OrderStatuses
		primary key nonclustered
        hash with (bucket_count=1024),
	Name varchar(40) not null,
)
with (memory_optimized=on, durability=schema_only);
go


create table Delivery.Orders
(
	OrderId int not null Identity(1,1)
		constraint PK_Orders 
		primary key nonclustered,
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
		default sysutcdatetime(),
	Notes nvarchar(max) null,
		
	index IdX_Orders_OrderNum
	nonclustered(OrderNum),

	index IdX_Orders_CustomerId
	nonclustered hash(CustomerId)
	with (bucket_count = 524288),

	constraint FK_Orders_Customers
	foreign key(CustomerId)
	references Delivery.Customers(CustomerId)

	-- You should consIder creating additional indexes
	-- and FK constraints in production system
)
with (memory_optimized=on, durability=schema_only);
go

create proc Delivery.InsertOrder
(
	@OrderNum varchar(20) not null
	,@Reference varchar(64) null
	,@CustomerId int not null
	,@PickupAddressId int not null 
	,@DeliveryAddressId int not null
	,@ServiceId int not null
	,@RatePlanId int not null
	,@OrderStatusId int not null
	,@DriverId int null
	,@Pieces smallint not null
	,@Amount smallmoney not null
	,@Notes nvarchar(max) null
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
		,RatePlanId,OrderStatusId,DriverId,Pieces,Amount,Notes)
	values(@OrderNum,GetDate(),@Reference,@CustomerId
		,@PickupAddressId,@DeliveryAddressId,@ServiceId
		,@RatePlanId,@OrderStatusId,@DriverId,@Pieces,@Amount,@Notes)
end
go

create proc Delivery.DeleteCustomer
(
	@CustomerId int not null
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

begin tran
	insert into Delivery.OrderStatuses(Name)
		select 'NEW' union all 
		select 'DISPATCHED' union all
		select 'IN ROUTE' union all
		select 'COMPLETED'
		
	insert into Delivery.Services(ServiceId,Name)
		select 1, 'BASE' union all
		select 2, 'RUSH' union all
		select 3, '2-HOURS' 
		
	insert into Delivery.RatePlans(RatePlanId, Name)
		select 1, 'REGULAR' union all
		select 2, 'CORPORATE' 

	insert into Delivery.Rates(ServiceId, RatePlanId, Rate)
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
,Ids(Id) as (select row_number() over (order by (select null)) from N6)
,Info(OrderId, CustomerId, OrderDateOffset, RatePlanId, ServiceId, Pieces)
as
(
	select 
		Id, Id % @MaxCustomers + 1, Id % (365*24*60)
		,Id % 2 + 1, Id % 3 + 1, Id % 5 + 1
	from Ids 
	where Id <= @MaxOrderId
)
,Info2(OrderId, OrderDate, OrderNum, CustomerId, RateplanId ,ServiceId
	,Pieces ,PickupAddressId, OrderStatusId, Rate, Notes)
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
		end, (OrderId % 5 + 1) * 10.
		,case 
			when OrderId % 20 = 0
			then replicate(N'A',400)
			else null
		end
	from Info
)	
insert into Delivery.Orders(OrderDate, OrderNum, CustomerId,
	PickupAddressId, DeliveryAddressId, ServiceId, RatePlanId,
	OrderStatusId, DriverId, Pieces, Amount, Notes)
select 
	o.OrderDate, o.OrderNum, o.CustomerId, o.PickupAddressId
	,case 
		when o.PickupAddressId % @MaxAddresses = 0
		then o.PickupAddressId + 1
		else o.PickupAddressId - 1
	end, o.ServiceId, o.RateplanId, o.OrderStatusId
	,case
		when o.OrderStatusId in (1,4)
		then NULL
		else OrderId % @MaxDrivers + 1
	end, o.Pieces, o.Rate, o.Notes
from Info2 o 	
go

