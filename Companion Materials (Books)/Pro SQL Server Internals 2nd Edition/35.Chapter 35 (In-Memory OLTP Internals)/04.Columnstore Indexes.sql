/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                  Chapter 35. In-Memory OLTP Internals                    */
/*                          Columnstore Indexes                             */
/****************************************************************************/

set noexec off
go

if convert(int,
		left(
			convert(nvarchar(128), serverproperty('ProductVersion')),
			charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
		)
) < 13 
begin
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3 or charindex('X64',@@Version) = 0
begin
	raiserror('That script requires 64-Bit Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

if not exists (select * from sys.databases where name = 'SQLServerInternalsHK')
begin
	raiserror('Create [SQLServerInternalsHK] database with "02.Create In-Memory OLTP DB.sql" script from "00.Init" project',16,1)
	set noexec on
end
go

use SQLServerInternalsHK
go

drop table if exists dbo.OrderItems
go

create table dbo.OrderItems
(
	OrderItemID int identity(1,1) not null
		constraint PK_OrderItems
		primary key nonclustered hash
		with (bucket_count = 16777316)
	,OrderId int not null
		index IDX_OrderId nonclustered
	,ArticleId int not null
	,SalesPrice money not null
	
	,index CCI_OrderItems clustered columnstore
	--with (compression_delay = 60)
)
with (memory_optimized = on, durability = schema_and_data);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,N6(C) as (select 0 from N5 as t1 cross join N4 as t2) -- 16,777,316 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N6)
insert into dbo.OrderItems(OrderId, ArticleId, SalesPrice)
	select ID / 3 + 1, ID % 50000, 49.99
	from Ids
	where ID <= 1000000;

-- You should see all new rows in the delta store table heap
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
    c.object_id = object_id('dbo.OrderItems');
go

set statistics time on

select top 10 ArticleId, avg(SalesPrice)
from dbo.OrderItems
group by ArticleId
order by avg(SalesPrice) desc;

set statistics time off
go

-- 10 minutes - just to be sure
waitfor delay '00:10:00.000';
go

-- Data should be compressed at this stage
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
    c.object_id = object_id('dbo.OrderItems');
go

set statistics time on

select top 10 ArticleId, avg(SalesPrice)
from dbo.OrderItems
group by ArticleId
order by avg(SalesPrice) desc;

set statistics time off
go


-- Deleting 80% of the rows
delete from dbo.OrderItems
where OrderItemId % 10 < 8;
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
            c.object_id = i.object_id and c.index_id = i.index_id
where
    c.object_id = object_id('dbo.OrderItems');
go



set statistics time on

select top 10 ArticleId, avg(SalesPrice)
from dbo.OrderItems
group by ArticleId
order by avg(SalesPrice) desc;

set statistics time off
go


-- Clean up to free up the memory
drop table if exists dbo.OrderItems;
go