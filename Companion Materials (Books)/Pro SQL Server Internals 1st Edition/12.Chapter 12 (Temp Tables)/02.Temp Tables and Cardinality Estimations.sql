/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                     Chapter 12. Temporary Tables                         */
/*           Temporary Tables: Improving Cardinality Estimations            */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if object_id(N'dbo.ParseIDList','TF') is not null
	drop function dbo.ParseIDList
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Orders12'    
)
	drop table dbo.Orders12
go

create table dbo.Orders12
(
	OrderId int not null,
	CustomerId int not null,
	Amount money not null,
	Placeholder char(100),
	
	constraint PK_Orders12
	primary key clustered(OrderId)
);

create index IDX_Orders_CustomerId on dbo.Orders12(CustomerId)
go

with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.Orders12(OrderId, CustomerId, Amount)
	select ID, ID % 250 + 1, Id % 50
	from IDs
go

create function dbo.ParseIDList(@List varchar(8000))
returns @IDList table
(
	ID int
)
as
begin
	if (IsNull(@List,'') = '')
		return 

	if (right(@List,1) <> ',')
		select @List = @List + ','

	;with CTE(F, L)
	as
	(
		select 1, charindex(',',@List)
		union all
		select L + 1, charindex(',',@List,L + 1)
		from CTE
		where charindex(',',@List,L + 1) <> 0
	)
	insert into @IDList(ID)
		select distinct convert(int,substring(@List,F,L-F))
		from CTE
	option (maxrecursion 0);
	
	return
end
go


/**********************************************************
Improving Cardinality Estimates

You can use the following code to generate CSV list

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N4)
select @List = convert(varchar(8000),
		(
			select ID as [text()], ',' as [text()]
			from IDs
			where ID <= 250
			for xml path('')
		)
	) 
**********************************************************/

-- Enable "Include Actual Execution Plan"
-- Check Actual vs. Estimated # of rows
-- Disable execution plan when you compare execution time

declare
	@List varchar(8000) 

select @List = '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250'

set statistics io, time on

select sum(o.Amount)
from dbo.Orders12 o join dbo.ParseIDList(@List) l on
	o.CustomerID = l.ID
     
set statistics io, time off
go

declare
	@List varchar(8000) 

select @List = '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250'

set statistics io, time on

create table #Customers(ID int not null primary key)
insert into #Customers(ID)
	select ID from dbo.ParseIDList(@List)
	
select sum(o.Amount)
from dbo.Orders12 o join #Customers c on
	o.CustomerID = c.ID

set statistics io, time off
drop table #Customers
go
