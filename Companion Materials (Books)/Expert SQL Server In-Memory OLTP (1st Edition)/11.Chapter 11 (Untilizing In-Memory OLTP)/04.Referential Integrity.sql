/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*                  04.Enforcing Referential Integrity                      */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertOrders' and s.name = 'dbo') drop proc dbo.InsertOrders;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'GetTopCustomers' and s.name = 'dbo') drop proc dbo.GetTopCustomers;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'DeleteCustomersAndOrders' and s.name = 'dbo') drop proc dbo.DeleteCustomersAndOrders;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'InsertOrderLineItems') drop proc dbo.InsertOrderLineItems; 
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'DeleteOrder') drop proc dbo.DeleteOrder; 
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Orders') drop table dbo.Orders; 
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'OrderLineItems') drop table dbo.OrderLineItems;
if exists(select * from sys.table_types t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'tvpOrderLineItems') drop type dbo.tvpOrderLineItems; 
go

create table dbo.Orders
(
	OrderId int not null identity(1,1)
		constraint PK_Orders
		primary key nonclustered hash 
		with (bucket_count=1000000),
	OrderNum varchar(32) 
		collate Latin1_General_100_BIN2 not null,
	OrderDate datetime2(0) not null
		constraint DEF_Orders_OrderDate
		default GetUtcDate(),
	/* Other Columns */
	index IDX_Orders_OrderNum
	nonclustered(OrderNum)
)
with (memory_optimized = on, durability = schema_and_data);

create table dbo.OrderLineItems
(
	OrderId int not null,
	OrderLineItemId int not null identity(1,1)
		constraint PK_OrderLineItems
		primary key nonclustered hash 
		with (bucket_count=10000000),
	ArticleId int not null,
	Quantity decimal(8,2) not null,
	Price money not null,
	/* Other Columns */

	index IDX_OrderLineItems_OrderId
	nonclustered hash(OrderId)
	with (bucket_count=1000000)
)
with (memory_optimized = on, durability = schema_and_data);
go

create type dbo.tvpOrderLineItems as table
(
	ArticleId int not null
		primary key nonclustered hash
		with (bucket_count = 1024),
	Quantity decimal(8,2) not null,
	Price money not null
	/* Other Columns */
)
with (memory_optimized = on);
go

create proc dbo.DeleteOrder
(
	@OrderId int not null
)
with native_compilation, schemabinding, execute as owner
as
begin atomic
with 
(
	transaction isolation level = serializable
	,language=N'English'
)
	-- This stored procedure emulates ON DELETE NO ACTION 
	-- foreign key constraint behavior
	declare
		@Exists bit = 0

	select @Exists = 1
	from dbo.OrderLineItems
	where OrderId = @OrderId

	if @Exists = 1
	begin
		;throw 60000, 'Referential Integrity Violation', 1;
		return
	end
	
	delete from dbo.Orders where OrderId = @OrderId
end
go

create proc dbo.InsertOrderLineItems
(
	@OrderId int not null
	,@OrderLineItems dbo.tvpOrderLineItems readonly 
)
with native_compilation, schemabinding, execute as owner
as
begin atomic
with 
(
	transaction isolation level = repeatable read
	,language=N'English'
)
	declare
		@Exists bit = 0

	select @Exists = 1
	from dbo.Orders
	where OrderId = @OrderId

	if @Exists = 0
	begin
		;throw 60001, 'Referential Integrity Violation', 1;
		return
	end
	
	insert into dbo.OrderLineItems(OrderId, ArticleId, Quantity, Price)
		select @OrderId, ArticleId, Quantity, Price
		from @OrderLineItems
end
go

	
