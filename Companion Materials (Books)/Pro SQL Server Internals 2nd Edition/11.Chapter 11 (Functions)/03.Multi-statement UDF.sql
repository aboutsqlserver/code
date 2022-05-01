/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 11. Functions                            */
/*                          Multi-statement UDF                             */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if object_id(N'dbo.udfClientOrders','TF') is not null drop function dbo.udfClientOrders;
if object_id(N'dbo.udfClientOrdersInline','IF') is not null drop function dbo.udfClientOrdersInline;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Orders') drop table dbo.Orders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Clients') drop table dbo.Clients;
go

create table dbo.Orders
(
	OrderId int not null identity(1,1),
	Clientid int not null,
	OrderDate datetime not null,
	OrderNumber varchar(32) not null,
	Amount smallmoney not null,
	IsActive bit not null,

	constraint PK_Orders
	primary key clustered(OrderId)
);

declare
	@StartDate datetime 

select @StartDate = '2016-01-01'

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2 ) -- 65,536 rows
,N6(C) AS (select 0 from N5 as T1 cross join N2 as T2 cross join N1 as T3) -- 524,288 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N6)
insert into dbo.Orders(ClientId,OrderDate,OrderNumber,Amount,IsActive)
	select
		ID % 256 + 1
		,dateadd(second,35 * ID,@StartDate)
		,'Order # ' + convert(varchar(6), ID)
		,10
		,case when ID % 10 = 0 then 1 else 0 end
	from Ids
	where ID <= 100000;
go

create table dbo.Clients
(
	ClientId int not null,
	ClientName varchar(32),
	
	constraint PK_Clients
	primary key clustered(ClientId)
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N4)
insert into dbo.Clients(ClientId, ClientName)
	select ID, 'Client # ' + convert(varchar(5), ID)
	from IDs;
go

create function dbo.udfClientOrders(@ClientId int)
returns @Orders table
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNumber varchar(32) not null,
	Amount smallmoney not null
)	
with schemabinding
as
begin
	insert into @Orders(OrderId, OrderDate, OrderNumber, Amount)
		select OrderId, OrderDate, OrderNumber, Amount
		from dbo.Orders
		where ClientId = @ClientId;
	return;
end
go

create function dbo.udfClientOrdersInline(@ClientId int)
returns table
as
return 
(
	select OrderId, OrderDate, OrderNumber, Amount
	from dbo.Orders
	where ClientId = @ClientId
)
go

-- Enable "Include Actual Execution Plan"
-- Compare Actual vs. Estimated # of rows
select c.ClientName, o.OrderId, o.OrderDate, o.OrderNumber, o.Amount
from dbo.Clients c cross apply dbo.udfClientOrders(c.ClientId) o
where c.ClientId = 1;

select c.ClientName, o.OrderId, o.OrderDate, o.OrderNumber, o.Amount
from dbo.Clients c cross apply dbo.udfClientOrdersInline(c.ClientId) o
where c.ClientId = 1;
go
