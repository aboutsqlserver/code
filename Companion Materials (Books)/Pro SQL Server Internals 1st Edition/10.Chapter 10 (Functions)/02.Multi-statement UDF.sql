/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 10. Functions                            */
/*                          Multi-statement UDF                             */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*  That script uses dbo.Orders10 table created in 01.Sclar UDF.sql script  */
/****************************************************************************/
if object_id(N'dbo.udfClientOrders','TF') is not null
	drop function dbo.udfClientOrders
go

if object_id(N'dbo.udfClientOrdersInline','IF') is not null
	drop function dbo.udfClientOrdersInline
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Clients10'    
)
	drop table dbo.Clients10
go

create table dbo.Clients10
(
	ClientId int not null,
	ClientName varchar(32),
	
	constraint PK_Clients10
	primary key clustered(ClientId)
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N4)
insert into dbo.Clients10(ClientId, ClientName)
	select ID, 'Client # ' + convert(varchar(5), ID)
	from IDs
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
		from dbo.Orders10
		where ClientId = @ClientId
	return
end
go

create function dbo.udfClientOrdersInline(@ClientId int)
returns table
as
return 
(
	select OrderId, OrderDate, OrderNumber, Amount
	from dbo.Orders10
	where ClientId = @ClientId
)
go

-- Enable "Include Actual Execution Plan"
-- Compare Actual vs. Estimated # of rows
select c.ClientName, o.OrderId, o.OrderDate, o.OrderNumber, o.Amount
from dbo.Clients10 c cross apply dbo.udfClientOrders(c.ClientId) o
where c.ClientId = 1;

select c.ClientName, o.OrderId, o.OrderDate, o.OrderNumber, o.Amount
from dbo.Clients10 c cross apply dbo.udfClientOrdersInline(c.ClientId) o
where c.ClientId = 1
go
