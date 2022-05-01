/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 13: Utilizing In-Memory OLTP                     */
/*                      07.Data Partitioning (SPs)                          */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop proc if exists dbo.InsertOrders2017_06;
drop proc if exists dbo.UpdateOrders2017_06;
drop proc if exists dbo.DeleteOrders2017_06;
drop proc if exists dbo.UpdateOrders2017;
drop proc if exists dbo.DeleteOrders2017;
go

create proc dbo.InsertOrders2017_06
(
	@OrderDate datetime2(0) not null
	,@CustomerId int not null
	,@Amount money not null
	,@Status tinyint not null
	,@OrderId bigint output
)
with native_compilation, schemabinding, execute as owner
as
begin atomic with
(
    transaction isolation level = snapshot
    ,language = N'English'
)
	insert into dbo.Orders2017_06(OrderDate,CustomerId,Amount,Status)
	values(@OrderDate, @CustomerId,@Amount,@Status);

	select @OrderId = scope_identity();
end
go

create proc dbo.UpdateOrders2017_06
(
	@OrderDate datetime2(0) not null
	,@OrderId bigint not null
	,@Status tinyint not null
)
with native_compilation, schemabinding, execute as owner
as
begin atomic with
(
    transaction isolation level = snapshot
    ,language = N'English'
)
	update dbo.Orders2017_06
	set @Status = @Status
	where OrderId = @OrderId
end
go

create proc dbo.DeleteOrders2017_06
(
	@OrderDate datetime2(0) not null
	,@OrderId bigint not null
)
with native_compilation, schemabinding, execute as owner
as
begin atomic with
(
    transaction isolation level = snapshot
    ,language = N'English'
)
	delete from dbo.Orders2017_06
	where OrderId = @OrderId;
end
go

create proc dbo.UpdateOrders2017
(
	@OrderDate datetime2(0) 
	,@OrderId bigint
	,@Status tinyint
)
as
	if @OrderDate < '2017-05-01'
		update dbo.Orders2017
		set @Status = @Status
		where OrderId = @OrderId and @OrderDate = @OrderDate
	else
		update dbo.Orders2017_05
		set @Status = @Status
		where OrderId = @OrderId
go

create proc dbo.DeleteOrders2017
(
	@OrderDate datetime2(0) 
	,@OrderId bigint
)
as
	if @OrderDate < '2017-05-01'
		delete from dbo.Orders2017
		where OrderId = @OrderId and @OrderDate = @OrderDate
	else 
		delete from dbo.Orders2017_05
		where OrderId = @OrderId
go
