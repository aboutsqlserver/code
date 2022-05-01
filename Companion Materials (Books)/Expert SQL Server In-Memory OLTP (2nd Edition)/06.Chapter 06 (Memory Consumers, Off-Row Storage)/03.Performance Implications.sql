/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 06: Memory Consumers and Off-Row Storage            */
/*                  03. Performance Impact of Off-Row Storage               */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists dbo.DataInRow
drop table if exists dbo.DataOffRow
go

create table dbo.DataInRow
(
	ID int not null
		constraint PK_DataInRow
		primary key nonclustered hash(ID)
		with (bucket_count = 262144)
	,Col1 varchar(3) not null
	,Col2 varchar(3) not null
	,Col3 varchar(3) not null
	,Col4 varchar(3) not null
	,Col5 varchar(3) not null
	,Col6 varchar(3) not null
	,Col7 varchar(3) not null
	,Col8 varchar(3) not null
	,Col9 varchar(3) not null
	,Col10 varchar(3) not null
	,Col11 varchar(3) not null
	,Col12 varchar(3) not null
	,Col13 varchar(3) not null
	,Col14 varchar(3) not null
	,Col15 varchar(3) not null
	,Col16 varchar(3) not null
	,Col17 varchar(3) not null
	,Col18 varchar(3) not null
	,Col19 varchar(3) not null
	,Col20 varchar(3) not null
)
with (memory_optimized = on, durability = schema_only);

create table dbo.DataOffRow
(
	ID int not null
		constraint PK_DataOffRow
		primary key nonclustered hash(ID)
		with (bucket_count = 262144)
	,Col1 varchar(max) not null
	,Col2 varchar(max) not null
	,Col3 varchar(max) not null
	,Col4 varchar(max) not null
	,Col5 varchar(max) not null
	,Col6 varchar(max) not null
	,Col7 varchar(max) not null
	,Col8 varchar(max) not null
	,Col9 varchar(max) not null
	,Col10 varchar(max) not null
	,Col11 varchar(max) not null
	,Col12 varchar(max) not null
	,Col13 varchar(max) not null
	,Col14 varchar(max) not null
	,Col15 varchar(max) not null
	,Col16 varchar(max) not null
	,Col17 varchar(max) not null
	,Col18 varchar(max) not null
	,Col19 varchar(max) not null
	,Col20 varchar(max) not null
)
with (memory_optimized = on, durability = schema_only);

declare
	@Nums table(Num int not null primary key)

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,N6(C) as (select 0 from N5 as t1 cross join N1 as t2) -- 131,072 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N6)
insert into @Nums(Num)
	select Id from Ids where Id <= 100000;

set statistics time on
insert into dbo.DataInRow(ID,Col1,Col2,Col3,Col4,Col5,Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,Col14,Col15,Col16,Col17,Col18,Col19,Col20)
	select Num,'0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0'
	from @Nums;

insert into dbo.DataOffRow(ID,Col1,Col2,Col3,Col4,Col5,Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,Col14,Col15,Col16,Col17,Col18,Col19,Col20)
	select Num,'0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0'
	from @Nums;
set statistics time off
go

select 
    i.name as [Index], i.index_id, a.xtp_object_id, a.type_desc, a.minor_id
    ,c.memory_consumer_id, c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes / 1024 as [Allocated KB]
    ,c.used_bytes / 1024 as [Used KB]	
from 
    sys.dm_db_xtp_memory_consumers c join
        sys.memory_optimized_tables_internal_attributes a on
            a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
    left outer join sys.indexes i on
            c.object_id = i.object_id and c.index_id = i.index_id and a.minor_id = 0
where
    c.object_id = object_id('dbo.DataInRow');
go

select 
    i.name as [Index], i.index_id, a.xtp_object_id, a.type_desc, a.minor_id
    ,c.memory_consumer_id, c.memory_consumer_type_desc as [mc type]
    ,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
    ,c.allocated_bytes / 1024 as [Allocated KB]
    ,c.used_bytes / 1024 as [Used KB]
from 
    sys.dm_db_xtp_memory_consumers c join
        sys.memory_optimized_tables_internal_attributes a on
            a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
    left outer join sys.indexes i on
            c.object_id = i.object_id and c.index_id = i.index_id and a.minor_id = 0
where
    c.object_id = object_id('dbo.DataOffRow');
go

select 
   sum(c.allocated_bytes) / 1024 as [Allocated KB]
    ,sum(c.used_bytes) / 1024 as [Used KB]	
from 
    sys.dm_db_xtp_memory_consumers c
where
    c.object_id = object_id('dbo.DataInRow');
go

select 
   sum(c.allocated_bytes) / 1024 as [Allocated KB]
    ,sum(c.used_bytes) / 1024 as [Used KB]	
from 
    sys.dm_db_xtp_memory_consumers c 
where
    c.object_id = object_id('dbo.DataOffRow');
go

set statistics time on
select count(*)
from dbo.DataInRow
where Col1='0' and Col2='0' and Col3='0' and Col4='0' and Col5='0' and Col6='0' and Col7='0' and Col8='0' and Col9='0' and Col10='0' and Col11='0' and Col12='0' and Col13='0' and Col14='0' and Col15='0' and Col16='0' and Col17='0' and Col18='0' and Col19='0' and Col20='0';

select count(*)
from dbo.DataOffRow
where Col1='0' and Col2='0' and Col3='0' and Col4='0' and Col5='0' and Col6='0' and Col7='0' and Col8='0' and Col9='0' and Col10='0' and Col11='0' and Col12='0' and Col13='0' and Col14='0' and Col15='0' and Col16='0' and Col17='0' and Col18='0' and Col19='0' and Col20='0';

set statistics time off
go

set statistics time on
delete from dbo.DataInRow;
delete from dbo.DataOffRow;
set statistics time off
go

