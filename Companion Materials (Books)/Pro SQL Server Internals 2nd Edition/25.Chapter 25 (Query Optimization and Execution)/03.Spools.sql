/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 25. Query Optimization and Execution               */
/*                                  Spools                                  */
/****************************************************************************/


use [SqlServerInternals]
go

if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'Orders') drop view dbo.Orders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'OrderItems') drop table dbo.OrderItems;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Orders') drop table dbo.Orders;
go

create table dbo.Orders
(
	OrderID int not null,
	CustomerId int not null,
	Total money not null,
	constraint PK_Orders
	primary key clustered(OrderID)
)
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,Nums(Num) as (select row_number() over (order by (select null)) from N4)
	insert into dbo.Orders(OrderId, CustomerId, Total)
		select Num, Num % 10 + 1, Num
		from Nums;

-- Enable "Include Actual Execution Plan"

-- Example of Spool. 
select OrderId, CustomerID, Total
	,Sum(Total) over(partition by CustomerID) as [Total Customer Sales] 
from dbo.Orders;
go

-- Alternative version of the query
select o.OrderId, o.CustomerID, o.Total, o.Total
	,ot.TotalSales as [Total Customer Sales]
from 
	dbo.Orders o join
	(
		select customerid, sum(total) as TotalSales
		from dbo.Orders
		group by CustomerID
	) ot on
		o.CustomerID = ot.CustomerID;
go

