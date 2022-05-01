/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 13: Utilizing In-Memory OLTP                     */
/*                 07.Data Partitioning (Data Movements)                    */
/****************************************************************************/

set nocount on
set xact_abort on
go

use InMemoryOLTP2016
go

drop trigger if exists dbo.trgAfterUpdate;
drop trigger if exists dbo.trgAfterDelete;

drop table if exists dbo.OrdersUpdateQueue;
drop table if exists dbo.OrdersDeleteQueue;
drop table if exists dbo.Orders2017_05_Tmp;
go

create table dbo.OrdersUpdateQueue
(
	ID int not null identity(1,1)
		constraint PK_OrdersUpdateQueue
		primary key nonclustered hash
		with (bucket_count=262144),
	OrderId bigint not null, 
)
with (memory_optimized=on, durability=schema_and_data)
go


create table dbo.OrdersDeleteQueue
(
	ID int not null identity(1,1)
		constraint PK_OrdersDeleteQueue
		primary key nonclustered hash
		with (bucket_count=262144),
	OrderId bigint not null
)
with (memory_optimized=on, durability=schema_and_data)
go

create trigger trgAfterUpdate on dbo.Orders2017_05
with native_compilation, schemabinding
after update
as
begin atomic with
(
    transaction isolation level = snapshot
    ,language = N'English'
)
	insert into dbo.OrdersUpdateQueue(OrderId)
		select OrderId 
		from inserted
end
go

create trigger trgAfterDelete on dbo.Orders2017_05
with native_compilation, schemabinding
after delete
as
begin atomic with
(
    transaction isolation level = snapshot
    ,language = N'English'
)
	insert into dbo.OrdersDeleteQueue(OrderId)
		select OrderId 
		from deleted
end
go

create table dbo.Orders2017_05_Tmp
(
	OrderId bigint not null, 
	OrderDate datetime2(0) not null,
	CustomerId int not null,
	Amount money not null,
	Status tinyint not null,

	check (OrderDate >= '2017-05-01' and OrderDate < '2017-06-01')
)
on [FG2017]
go

create unique clustered index IDX_Orders2017_05_Tmp_OrderDate_OrderId
on dbo.Orders2017_05_Tmp(OrderDate, OrderId)
with (data_compression=row)
on [FG2017]
go

create nonclustered index IDX_Orders2017_05_Tmp_CustomerId
on  dbo.Orders2017_05_Tmp(CustomerId)
with (data_compression=row)
on [FG2017]
go

create nonclustered index IDX_Orders2017_05_Tmp_OrderId
on  dbo.Orders2017_05_Tmp(OrderId)
with (data_compression=row)
on [FG2017]
go

-- Step 1: Move data from the main table
insert into dbo.Orders2017_05_Tmp(OrderDate, OrderId, CustomerId, Amount, Status)
	select OrderDate, OrderId, CustomerId, Amount, Status
	from dbo.Orders2017_05 with (snapshot)
go

-- Step 2: Update/Delete
select count(*) as [In Update Queue] from dbo.OrdersUpdateQueue with (snapshot)
select count(*) as [In Delete Queue] from dbo.OrdersDeleteQueue with (snapshot)
go

declare
	@MaxUpdateId int
	,@MaxDeleteId int

select @MaxUpdateId = max(ID) from dbo.OrdersUpdateQueue with (snapshot);
select @MaxDeleteId = max(ID) from dbo.OrdersDeleteQueue with (snapshot);

begin tran
	 if @MaxUpdateId is not null
	begin
		update t
		set t.Amount = s.Amount, t.Status = s.Status
		from 
			dbo.OrdersUpdateQueue q with (snapshot) join dbo.Orders2017_05 s with (snapshot) on
				q.OrderId = s.OrderId 
			join dbo.Orders2017_05_Tmp t on
				t.OrderId = s.OrderId
		where
			q.ID <= @MaxUpdateId;
		
		delete from dbo.OrdersUpdateQueue with (snapshot)
		where ID <= @MaxUpdateId;
	end;

	if @MaxDeleteId is not null
	begin
		delete from t
		from 
			dbo.OrdersDeleteQueue q with (snapshot) join dbo.Orders2017_05_Tmp t on
				t.OrderId = q.OrderId
		where
			q.ID <= @MaxDeleteId;
		
		delete from dbo.OrdersDeleteQueue with (snapshot)
		where ID <= @MaxDeleteId;
	end

	select count(*) as [In Update Queue] from dbo.OrdersUpdateQueue with (snapshot)
	select count(*) as [In Delete Queue] from dbo.OrdersDeleteQueue with (snapshot)
commit
go

-- Step 3: Replace
set xact_abort on
set deadlock_priority 10
go

begin tran -- Keeping locks in place
go

-- Obtaining Sch-M locks on SPs
alter proc dbo.UpdateOrders2017
(
	@OrderDate datetime2(0) 
	,@OrderId bigint
	,@Amount money
	,@Status tinyint
)
as
	update dbo.Orders2017
	set Amount = @Amount, @Status = @Status
	where OrderId = @OrderId and @OrderDate = @OrderDate
go

alter proc dbo.DeleteOrders2017
(
	@OrderDate datetime2(0) 
	,@OrderId bigint
)
as
	delete from dbo.Orders2017
	where OrderId = @OrderId and @OrderDate = @OrderDate
go

update t
set t.Amount = s.Amount, t.Status = s.Status
from 
	dbo.OrdersUpdateQueue q with (snapshot) join dbo.Orders2017_05 s with (snapshot) on
		q.OrderId = s.OrderId 
	join dbo.Orders2017_05_Tmp t on
		t.OrderId = s.OrderId;

delete from t
from 
	dbo.OrdersDeleteQueue q with (snapshot) join dbo.Orders2017_05_Tmp t on
		t.OrderId = q.OrderId;

alter table dbo.Orders2017
	drop constraint CHK_Order2017_01_05
go

alter table dbo.Orders2017_05_Tmp switch to dbo.Orders2017 partition 5
go

alter view dbo.Orders(OrderDate, OrderId, CustomerId, Amount, Status)
as
	select OrderDate, OrderId, CustomerId, Amount, Status
	from dbo.Orders2017_06
	
	union all

	select OrderDate, OrderId, CustomerId, Amount, Status
	from dbo.Orders2017

	union all

	select OrderDate, OrderId, CustomerId, Amount, Status
	from dbo.Orders2016
go
commit
go

drop table dbo.Orders2017_05;
go

select max(OrderDate) from dbo.Orders2017;
go
