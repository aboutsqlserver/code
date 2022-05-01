/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 10. Functions                            */
/*                              Scalar UDF                                  */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if object_id(N'dbo.udfDateOnly','FN') is not null
	drop function dbo.udfDateOnly
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Orders10'    
)
	drop table dbo.Orders10
go

create table dbo.Orders10
(
	OrderId int not null identity(1,1),
	Clientid int not null,
	OrderDate datetime not null,
	OrderNumber varchar(32) not null,
	Amount smallmoney not null,
	IsActive bit not null,

	constraint PK_Orders10
	primary key clustered(OrderId)
);

declare
	@StartDate datetime 

select @StartDate = '2014-01-01'

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2 ) -- 65,536 rows
,N6(C) AS (select 0 from N5 as T1 cross join N2 as T2 cross join N1 as T3) -- 524,288 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N6)
insert into dbo.Orders10(ClientId,OrderDate,OrderNumber,Amount,IsActive)
	select
		ID % 256 + 1
		,dateadd(second,35 * ID,@StartDate)
		,'Order # ' + convert(varchar(6), ID)
		,10
		,case when ID % 10 = 0 then 1 else 0 end
	from Ids
	where ID <= 100000;
go

create function dbo.udfDateOnly(@Value datetime)
returns datetime
with schemabinding
as
begin
	return (convert(datetime,convert(varchar(10),@Value,121)))
end
go

set statistics time on
select count(*) 
from dbo.Orders10
where dbo.udfDateOnly(OrderDate) =  '2014-02-01'
set statistics time off
go

set statistics time on
select count(*) 
from dbo.Orders10
where convert(datetime,convert(varchar(10),OrderDate,121)) =  '2014-02-01'
set statistics time off
go

set statistics time on
select count(*) 
from dbo.Orders10
where OrderDate >= '2014-02-01' and OrderDate < '2014-02-02'
set statistics time off
go

create index IDX_Orders_OrderDate
on dbo.Orders10(OrderDate)
go

-- Enable "Include Execution Plan"
-- Index is not utilized
set statistics time on
select count(*) 
from dbo.Orders10
where convert(datetime,convert(varchar(10),OrderDate,121)) =  '2014-02-01'
set statistics time off
go

set statistics time on
select count(*) 
from dbo.Orders10
where OrderDate >= '2014-02-01' and OrderDate < '2014-02-02'
set statistics time off
go
