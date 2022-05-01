/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*         Creating objects for Part 5 "Locking and Blocking"               */
/****************************************************************************/
set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

if exists
(
	select * 
	from sys.databases 
	where database_id = DB_ID() and is_read_committed_snapshot_on = 1
)
begin
	raiserror('Please disable READ_COMMITTED_SNAPSHOT to continue',16,1) with nowait
	raiserror('You can do it with the following statement:',0,1) with nowait
	raiserror('ALTER DATABASE SqlServerInternals SET READ_COMMITTED_SNAPSHOT OFF WITH ROLLBACK IMMEDIATE',0,1) with nowait

	set noexec on
end
go




if not exists (select * from sys.schemas where name = 'Delivery')
	exec sp_executesql N'create schema [Delivery]'
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'Orders' and s.name = 'Delivery'
)
	drop table Delivery.Orders
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
from Info2 o 	
