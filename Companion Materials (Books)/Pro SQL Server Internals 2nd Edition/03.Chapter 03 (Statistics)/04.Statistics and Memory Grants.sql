/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 03. Statistics                           */
/*                      Statistics and Memory Grants                        */
/****************************************************************************/
set nocount on
go

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'MemoryGrantDemo') drop table dbo.MemoryGrantDemo;
go

create table dbo.MemoryGrantDemo
(
	ID int not null,
	Col int not null,
	Placeholder char(8000)
);

create unique clustered index IDX_MemoryGrantDemo_ID
on dbo.MemoryGrantDemo(ID);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.MemoryGrantDemo(ID,Col,Placeholder)
	select ID, ID % 100, convert(char(100),ID)
	from IDs;

create nonclustered index IDX_MemoryGrantDemo_Col 
on dbo.MemoryGrantDemo(Col);
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N2 as T2) -- 1,024 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.MemoryGrantDemo(ID,Col,Placeholder)
	select 100000 + ID, 1000, convert(char(100),ID)
	from IDs
	where ID <= 656;
go

-- Enable "Include Actual Execution Plan"
-- Check estimated # of rows vs. actual, Memory Grant size and Sort Warnings
declare
	@Dummy int
    
set statistics time on
select @Dummy = ID from dbo.MemoryGrantDemo where Col = 1 order by Placeholder;
select @Dummy = ID from dbo.MemoryGrantDemo where Col = 1000 order by Placeholder;
set statistics time off

