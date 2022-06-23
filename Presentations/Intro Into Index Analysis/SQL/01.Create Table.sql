/****************************************************************************/
/*                        Intro into Index Analysis                         */
/*																			*/
/*                         Dmitri V. Korotkevitch                           */
/*                        http://aboutsqlserver.com                         */
/*                          dk@aboutsqlserver.com                           */
/****************************************************************************/
/*                            Table Creation                                */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Customers' and s.name = 'dbo') drop table dbo.Customers;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Customers1' and s.name = 'dbo') drop table dbo.Customers1;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders' and s.name = 'dbo') drop table dbo.Orders;
go

create table dbo.Orders
(
	OrderId int not null identity(1,1),
	OrderSeq int not null,
	OrderNum varchar(32) not null,
	OrderDate smalldatetime not null,
	CustomerId uniqueidentifier not null,
	Amount money not null,
	StoreId int not null,
	Fulfilled bit not null
		constraint DEF_Orders_Fulfilled
		default(0),
	DeliveryInstructions char(500) not NULL
		constraint DEF_Orders_DeliveryInstructions
		default 'Placeholder'
)
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2 cross join N2 as T3) -- 1024 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 ) -- 1,048,576 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.Orders(OrderDate, OrderSeq, OrderNum, CustomerId, Amount, StoreId, FulFilled)
	select 
		dateadd(day,-ID % 365,GetDate())
		,ID
		,'Order: ' + convert(varchar(32),ID)
		,newid()
		,ID % 100
		,ID % 10
		,1
	from IDs; 
go

create unique clustered index IDX_Orders_OrderId
on dbo.Orders(OrderId);

create nonclustered index IDX_Orders_OrderNum
on dbo.Orders(OrderNum);

create nonclustered index IDX_Orders_CustomerId
on dbo.Orders(CustomerId);

create nonclustered index IDX_Orders_StoreID
on dbo.Orders(StoreId);
go

create nonclustered index IDX_Orders_OrderSeq
on dbo.Orders(OrderSeq);
go

create nonclustered index IDX_Orders_OrderDate
on dbo.Orders(OrderDate);
go

select count(*) as [Row Count] from dbo.Orders;

select StoreId, count(*) as [Count]
from dbo.Orders
group by StoreId;

