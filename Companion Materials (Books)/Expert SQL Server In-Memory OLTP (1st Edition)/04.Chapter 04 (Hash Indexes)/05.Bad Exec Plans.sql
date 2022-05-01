/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 04: Hash Indexes                           */
/*              05.Bad Execution Plans due to Missing Statistics            */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'T1' and s.name = 'dbo') drop table dbo.T1;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'T2' and s.name = 'dbo') drop table dbo.T2;
go

create table dbo.T1
(
	ID int not null identity(1,1)
		primary key nonclustered hash
		with (bucket_count = 8192),
    T1Col int not null,
    Placeholder char(100) not null
		constraint DEF_T1_Placeholder
		default('1'),

	index IDX_T1Col
	nonclustered hash(T1Col)
	with (bucket_count = 1024)
)
with (memory_optimized = on, durability = schema_only);

create table dbo.T2
(
	ID int not null identity(1,1)
		primary key nonclustered hash
		with (bucket_count = 8192),
	T2Col int not null,
	Placeholder char(100) not null
		constraint DEF_T2_Placeholder
		default('2'),
	
	index IDX_T2Col
	nonclustered hash(T2Col)
	with (bucket_count = 1024)
)
with (memory_optimized = on, durability = schema_only);
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N3 as t2) -- 4,096 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N5)
insert into dbo.T1(T1Col)
	select 1 from Ids;

insert into dbo.T2(T2Col)
	select -1 from dbo.T1;

update dbo.T1 
set T1Col = 2
where ID = 4096;

update dbo.T2
set T2Col = -2
where ID = 1;
go

/* Data Distribution in the Tables */
select 'T1' as [Table], T1Col as [Value], count(*) as [Count]
from dbo.T1
group by T1Col

union all

select 'T2' as [Table], T2Col as [Value], count(*) as [Count]
from dbo.T2
group by T2Col;

/* Check Execution Plans */
select * 
from dbo.T1 t1 join dbo.T2 t2 on 
	t1.ID = t2.ID
where
	t1.T1Col = 2 and 
	t2.T2Col = -1;

select * 
from dbo.T1 t1 join dbo.T2 t2 on 
	t1.ID = t2.ID
where
	t1.T1Col = 1 and 
	t2.T2Col = -2;
go

/* Update Statistics */
update statistics dbo.T1 with fullscan, norecompute;
update statistics dbo.T2 with fullscan, norecompute;

dbcc show_statistics('dbo.T1','IDX_T1Col');
dbcc show_statistics('dbo.T2','IDX_T2Col');
go

/* Check Execution Plans */
select * 
from dbo.T1 t1 join dbo.T2 t2 on 
	t1.ID = t2.ID
where
	t1.T1Col = 2 and 
	t2.T2Col = -1;

select * 
from dbo.T1 t1 join dbo.T2 t2 on 
	t1.ID = t2.ID
where
	t1.T1Col = 1 and 
	t2.T2Col = -2;
go



