/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 09: Garbage Collection                       */
/*                           01.Table Creation                              */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'GCDemo' and s.name = 'dbo') drop table dbo.GCDemo;
go


/** RESTART SQL SERVER BEFORE THE TEST **/

create table dbo.GCDemo
(
	ID int not null,
	Placeholder char(8000) not null,

	constraint PK_GCDemo
	primary key nonclustered hash(ID) 
	with (bucket_count=16384),
)
with (memory_optimized=on, durability=schema_only)  
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N5)
insert into dbo.GCDemo(Id, Placeholder)
	select Id, Replicate('0',8000)
	from ids
go
