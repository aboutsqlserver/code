/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 06: In-Memory OLTP Programmability                 */
/*                         03.Performance Comparison                        */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertCustomers_Row' and s.name = 'dbo') drop proc dbo.InsertCustomers_Row;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertCustomers_Batch' and s.name = 'dbo') drop proc dbo.InsertCustomers_Batch;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertCustomers_NativelyCompiled' and s.name = 'dbo') drop proc dbo.InsertCustomers_NativelyCompiled;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'UpdateCustomers' and s.name = 'dbo') drop proc dbo.UpdateCustomers;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertOrders' and s.name = 'dbo') drop proc dbo.InsertOrders;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'GetTopCustomers' and s.name = 'dbo') drop proc dbo.GetTopCustomers;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'DeleteCustomersAndOrders' and s.name = 'dbo') drop proc dbo.DeleteCustomersAndOrders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Customers' and s.name = 'dbo') drop table dbo.Customers;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Orders' and s.name = 'dbo') drop table dbo.Orders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Numbers' and s.name = 'dbo') drop table dbo.Numbers;
go

create table dbo.Customers
(
	CustomerId int not null 
		primary key nonclustered
		hash with (bucket_count=200000),
	Name nvarchar(255)
		collate Latin1_General_100_BIN2 not null,
	CreatedOn datetime2(0) not null
		constraint DEF_Customers_CreatedOn
		default sysutcdatetime(),
	Placeholder char(200) not null,

	index IDX_Name nonclustered(Name)
)
with (memory_optimized=on, durability=schema_only);

create table dbo.Orders
(
	OrderId int not null 
		primary key nonclustered
		hash with (bucket_count=5000000),
	CustomerId int not null,
	OrderNum varchar(32)
		collate Latin1_General_100_BIN2 not null,
	OrderDate datetime2(0) not null
		constraint DEF_Orders_OrderDate
		default sysutcdatetime(),
	Amount money not null,
	Placeholder char(200) not null,

	index IDX_CustomerId 
	nonclustered hash(CustomerId)
	with (bucket_count=200000),

	index IDX_OrderNum nonclustered(OrderNum)
)
with (memory_optimized=on, durability=schema_only);

create table dbo.Numbers
(
	Num int not null
		constraint PK_Numbers
		primary key clustered
);
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,N6(C) as (select 0 from N5 as t1 cross join N3 as t2) -- 1,048,576 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N6)
insert into dbo.Numbers(Num)
	select Id from Ids;
go
create proc dbo.InsertCustomers_Row
(
	@NumCustomers int
)
as
begin
	set nocount on
	set xact_abort on

	declare
		@I int = 1;
	
	begin tran
		while @I <= @NumCustomers
		begin
			insert into dbo.Customers(CustomerId,Name,Placeholder)
			values(@I,N'Customer ' + convert(nvarchar(10),@I), 'Some data');

			set @I += 1;
		end;
	commit
end
go

create proc dbo.InsertCustomers_Batch
(
	@NumCustomers int
)
as
begin
	set nocount on
	set xact_abort on

	if @NumCustomers > 1048576
	begin
		raiserror('@NumCustomers should not exceed 1,048,576',10,1);
		return;
	end;
	
	begin tran
		insert into dbo.Customers(CustomerId,Name,Placeholder)
			select Num, N'Customer ' + convert(nvarchar(10),Num), 'Some data'
			from dbo.Numbers
			where Num <= @NumCustomers
	commit
end
go

create proc dbo.InsertCustomers_NativelyCompiled
(
	@NumCustomers int not null
)
with native_compilation, schemabinding, execute as owner
as
begin atomic with 
(
	transaction isolation level = snapshot
	,language = N'English'
)
	declare
		@I int = 1;
	
	while @I <= @NumCustomers
	begin
		insert into dbo.Customers(CustomerId,Name,Placeholder)
		values(@I,N'Customer ' + convert(nvarchar(10),@I), 'Some data');

		set @I += 1;
	end;
end
go

/* Testing Insert Performance */
-- InsertCustomers_Row
delete from dbo.Customers;
declare
	@DT datetime = getDate();
exec dbo.InsertCustomers_Row @NumCustomers = 10000;
select datediff(millisecond,@DT, GetDate()) as [Row 10K];

delete from dbo.Customers;
select @DT = getdate(); 
exec dbo.InsertCustomers_Row @NumCustomers = 50000;
select datediff(millisecond,@DT, GetDate()) as [Row 50K];

delete from dbo.Customers;
select @DT = getdate(); 
exec dbo.InsertCustomers_Row @NumCustomers = 100000;
select datediff(millisecond,@DT, GetDate()) as [Row 100K];
go


-- InsertCustomers_Batch
delete from dbo.Customers;
declare
	@DT datetime = getDate();
exec dbo.InsertCustomers_Batch @NumCustomers = 10000;
select datediff(millisecond,@DT, GetDate()) as [Batch 10K];

delete from dbo.Customers;
select @DT = getdate(); 
exec dbo.InsertCustomers_Batch @NumCustomers = 50000;
select datediff(millisecond,@DT, GetDate()) as [Batch 50K];

delete from dbo.Customers;
select @DT = getdate(); 
exec dbo.InsertCustomers_Batch @NumCustomers = 100000;
select datediff(millisecond,@DT, GetDate()) as [Batch 100K];
go

-- InsertCustomers_NativelyCompiled
delete from dbo.Customers;
declare
	@DT datetime = getDate();
exec dbo.InsertCustomers_NativelyCompiled 10000;
select datediff(millisecond,@DT, GetDate()) as [Natively Compileda 10K];

delete from dbo.Customers;
select @DT = getdate(); 
exec dbo.InsertCustomers_NativelyCompiled 50000;
select datediff(millisecond,@DT, GetDate()) as [Natively Compileda 50K];

delete from dbo.Customers;
select @DT = getdate(); 
exec dbo.InsertCustomers_NativelyCompiled 100000;
select datediff(millisecond,@DT, GetDate()) as [Natively Compileda 100K];
go

create proc dbo.UpdateCustomers
(
	@Placeholder char(100) not null
)
with native_compilation, schemabinding, execute as owner
as
begin atomic with 
(
	transaction isolation level = snapshot
	,language = N'English'
)
	update dbo.Customers
	set Placeholder = @Placeholder
	where CustomerId % 2 = 0;
end
go

/* Testing updates */
declare
	@DT datetime = getDate();
exec dbo.UpdateCustomers 'Using Natively Compiled SP'; 
select datediff(millisecond,@DT, GetDate()) as [Update Natively Compiled];

select @DT = getdate(); 
update dbo.Customers
set Placeholder = 'Using interop engine' 
where CustomerId % 2 = 1;
select datediff(millisecond,@DT, GetDate()) as [Update Interop]
go

/* Populating Orders table */
insert into dbo.Orders(OrderId, CustomerId, OrderNum, Amount,Placeholder)
	select
		Num
		,Num % 100000 + 1 
		,'Order ' + convert(nvarchar(10),Num)
		,Num / 100.
		,'Some data'
	from Numbers
	where Num <= 1000000
go

/* Select Performance */
create proc dbo.GetTopCustomers
with native_compilation, schemabinding, execute as owner
as
begin atomic with 
(
	transaction isolation level = snapshot
	,language = N'English'
)
	select top 10
		c.CustomerId, c.Name, count(o.OrderId) as [Order Cnt]
		,max(o.OrderDate) as [Most Recent Order Date]
		,sum(o.Amount) as [Total Amount]
	from
		dbo.Customers c join dbo.Orders o on
			c.CustomerId = o.CustomerId
	group by
		c.CustomerId, c.Name
	order by
		sum(o.Amount) desc;
end
go

declare
	@DT datetime = getDate();
exec dbo.GetTopCustomers
select datediff(millisecond,@DT, GetDate()) as [GetTopCustomers]

select @DT = getdate(); 
	select top 10
		c.CustomerId, c.Name, count(o.OrderId) as [Order Cnt]
		,max(o.OrderDate) as [Most Recent Order Date]
		,sum(o.Amount) as [Total Amount]
	from
		dbo.Customers c join dbo.Orders o on
			c.CustomerId = o.CustomerId
	group by
		c.CustomerId, c.Name
	order by
		sum(o.Amount) desc;
select datediff(millisecond,@DT, GetDate()) as [Update Interop]
go

/* Delete Performance */

create proc dbo.DeleteCustomersAndOrders
with native_compilation, schemabinding, execute as owner
as
begin atomic with 
(
	transaction isolation level = snapshot
	,language = N'English'
)
	delete from dbo.Orders;
	delete from dbo.Customers;
end
go

declare
	@DT datetime = getDate();
exec dbo.DeleteCustomersAndOrders
select datediff(millisecond,@DT, GetDate()) as [DeleteCustomersAndOrders];
go

-- Repopulating the data
exec dbo.InsertCustomers_NativelyCompiled 100000;
insert into dbo.Orders(OrderId, CustomerId, OrderNum, Amount,Placeholder)
	select
		Num
		,Num % 100000 + 1 
		,'Order ' + convert(nvarchar(10),Num)
		,Num / 100.
		,'Some data'
	from Numbers
	where Num <= 1000000
go

declare
	@DT datetime = getDate();
select @DT = getdate(); 
	delete from dbo.Orders;
	delete from dbo.Customers;
select datediff(millisecond,@DT, GetDate()) as [Delete Interop]
go
