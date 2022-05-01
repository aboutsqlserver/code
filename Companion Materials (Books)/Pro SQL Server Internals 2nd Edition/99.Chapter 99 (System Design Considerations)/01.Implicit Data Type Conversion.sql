/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                         dk@aboutsqlserver.com                            */
/****************************************************************************/
/*                Chapter 16. System Design Considerations                  */
/*                      Implicit Data Type Conversion                       */
/****************************************************************************/

use [SqlServerInternals]
go


if exists(
	select * 
	from sys.procedures p join sys.schemas s on 
		p.schema_id = s.schema_id
	where 
		p.name = 'SearchCustomerByName' and s.name = 'dbo' 
)
	drop proc dbo.SearchCustomerByName;
go


if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'Customers' and s.name = 'dbo'
)
	drop table dbo.Customers;
go

create table dbo.Customers
(
	CustomerId int not null,
	CustomerName varchar(64) not null,
	Placeholder char(100),
	
	constraint PK_Customers
	primary key clustered(CustomerId)
)
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.Customers(CustomerId, CustomerName)
	select ID, 'Customer ' + convert(varchar(5),ID)
	from IDs;
go

create unique index IDX_Customers_Name
on dbo.Customers(CustomerName);
go

create proc dbo.SearchCustomerByName
(
	@CustomerName varchar(64)
)
as
	select CustomerId, CustomerName, PlaceHolder
	from dbo.Customers
	where CustomerName = @CustomerName;
go

-- Enable "Include Actual Execution Plan"

exec sp_executesql
	@SQL = 
N'select CustomerId, CustomerName, PlaceHolder
from dbo.Customers
where CustomerName = @CustomerName'
	,@Params = N'@CustomerName nvarchar(64)'
	,@CustomerName = N'Customer 42';

exec sp_executesql
	@SQL = N'exec dbo.SearchCustomerByName @CustomerName'
	,@Params = N'@CustomerName nvarchar(64)'
	,@CustomerName = N'Customer 42';
