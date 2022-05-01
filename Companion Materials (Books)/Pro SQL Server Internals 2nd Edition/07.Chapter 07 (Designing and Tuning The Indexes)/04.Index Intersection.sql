/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 07. Designing and Tuning The Indexes               */
/*                            Index Intersection                            */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'IndexIntersection') drop table dbo.IndexIntersection;
go

create table dbo.IndexIntersection
(
	Id int not null,
	Placeholder char(100),
	Col1 int not null,
	Col2 int not null,
	Col3 int not null
);

create unique clustered index IDX_IndexIntersection_ID
on dbo.IndexIntersection(ID);    

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,N6(C) as (select 0 from N3 as T1 CROSS JOIN N5 as T2) -- 1,048,576 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N6)
insert into dbo.IndexIntersection(ID, Col1, Col2, Col3)
	select ID, ID % 50, ID % 150, ID % 200
	from IDs;

create nonclustered index IDX_IndexIntersection_Col1
on dbo.IndexIntersection(Col1);  
create nonclustered index IDX_IndexIntersection_Col2
on dbo.IndexIntersection(Col2);  
create nonclustered index IDX_IndexIntersection_Col3
on dbo.IndexIntersection(Col3);
go

-- Enable "Include Actual Execution Plan"
-- Check Actual vs. Estimated # of rows
select ID
from dbo.IndexIntersection 
where Col1 = 42 and Col2 = 43 and Col3 = 44;
go

create nonclustered index IDX_IndexIntersection_Col3_Included
on dbo.IndexIntersection(Col3)
include (Col1, Col2);
go

select ID
from dbo.IndexIntersection 
where Col1 = 42 and Col2 = 43 and Col3 = 44;
go
