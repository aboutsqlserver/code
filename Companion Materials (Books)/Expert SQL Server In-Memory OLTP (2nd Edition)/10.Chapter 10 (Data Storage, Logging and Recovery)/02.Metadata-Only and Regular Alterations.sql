/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 10: Data Storage, Logging and Recovery              */
/*                 02.Metadata-Only and Regular Alterations                 */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists dbo.TableA;
drop table if exists dbo.TableB;
go

create table dbo.TableA
(
	Col1 int not null
		constraint PK_TableA
		primary key nonclustered hash
		with (bucket_count=1024),
)
with (memory_optimized=on, durability=schema_and_data);

create table dbo.TableB
(
	Col1 int not null
		constraint PK_TableB
		primary key nonclustered hash
		with (bucket_count=1024),
)
with (memory_optimized=on, durability=schema_and_data);

select 
    'dbo.TableA' as [Table]
	,c.index_id, a.xtp_object_id, a.type_desc, a.minor_id
    ,c.memory_consumer_id, c.memory_consumer_type_desc as [mc type]
from 
    sys.dm_db_xtp_memory_consumers c join
        sys.memory_optimized_tables_internal_attributes a on
            a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
where
    c.object_id = object_id('dbo.TableA');

select 
    'dbo.TableB' as [Table]
    ,c.index_id, a.xtp_object_id, a.type_desc, a.minor_id
    ,c.memory_consumer_id, c.memory_consumer_type_desc as [mc type]
from 
    sys.dm_db_xtp_memory_consumers c join
        sys.memory_optimized_tables_internal_attributes a on
            a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
where
    c.object_id = object_id('dbo.TableB');
go

alter table dbo.TableA
add constraint CHK_Col1
check (Col1 > 0)
go

alter table dbo.TableB
add Col2 int null
go

select 
    'dbo.TableA' as [Table]
    ,c.index_id, a.xtp_object_id, a.type_desc, a.minor_id
    ,c.memory_consumer_id, c.memory_consumer_type_desc as [mc type]
from 
    sys.dm_db_xtp_memory_consumers c join
        sys.memory_optimized_tables_internal_attributes a on
            a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
where
    c.object_id = object_id('dbo.TableA');

select 
    'dbo.TableB' as [Table]
	,c.index_id, a.xtp_object_id, a.type_desc, a.minor_id
    ,c.memory_consumer_id, c.memory_consumer_type_desc as [mc type]
from 
    sys.dm_db_xtp_memory_consumers c join
        sys.memory_optimized_tables_internal_attributes a on
            a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
where
    c.object_id = object_id('dbo.TableB');
go
