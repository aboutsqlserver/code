/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                          Chapter 09. Triggers                            */
/*                        Triggers and Fragmentation                        */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Data') drop table dbo.Data;
go

create table dbo.Data
(
	ID int not null identity(1,1),
	Value int not null,
	Placeholder char(50)
		constraint DEF_Data_Placeholder
		default 'Placeholder',

	constraint PK_Data
	primary key clustered(ID)
)
go

/*** Everything is in-row; no fragmentation */
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.data(Value)
	select ID from Ids;

select 
	   alloc_unit_type_desc as [AllocUnit],
       index_level, 
       page_count, 
       avg_page_space_used_in_percent as [SpaceUsed], 
       avg_fragmentation_in_percent as [Frag %],
       min_record_size_in_bytes as [MinSize],
       max_record_size_in_bytes as [MaxSize],
       avg_record_size_in_bytes as [Avgsize]
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.Data'),1,null,'DETAILED');
go 

update dbo.Data set value = 1;

select 
	   alloc_unit_type_desc as [AllocUnit],
       index_level, 
       page_count, 
       avg_page_space_used_in_percent as [SpaceUsed], 
       avg_fragmentation_in_percent as [Frag %],
       min_record_size_in_bytes as [MinSize],
       max_record_size_in_bytes as [MaxSize],
       avg_record_size_in_bytes as [Avgsize]
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.Data'),1,null,'DETAILED');
go

create trigger trgDataAU 
on dbo.data
after update
as     
       return;
go

update dbo.data set value = 2;

select 
	   alloc_unit_type_desc as [AllocUnit],
       index_level, 
       page_count, 
       avg_page_space_used_in_percent as [SpaceUsed], 
       avg_fragmentation_in_percent as [Frag %],
       min_record_size_in_bytes as [MinSize],
       max_record_size_in_bytes as [MaxSize],
       avg_record_size_in_bytes as [Avgsize]
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.Data'),1,null,'DETAILED');
go 

/*** Adding LOB column ***/
alter table dbo.data 
add LobColumn varchar(max) null;
go

select 
	   alloc_unit_type_desc as [AllocUnit],
       index_level, 
       page_count, 
       avg_page_space_used_in_percent as [SpaceUsed], 
       avg_fragmentation_in_percent as [Frag %],
       min_record_size_in_bytes as [MinSize],
       max_record_size_in_bytes as [MaxSize],
       avg_record_size_in_bytes as [Avgsize]
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.Data'),1,null,'DETAILED');
go 

update dbo.data set value = 3;

select 
	   alloc_unit_type_desc as [AllocUnit],
       index_level, 
       page_count, 
       avg_page_space_used_in_percent as [SpaceUsed], 
       avg_fragmentation_in_percent as [Frag %],
       min_record_size_in_bytes as [MinSize],
       max_record_size_in_bytes as [MaxSize],
       avg_record_size_in_bytes as [Avgsize]
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Data'),1,null,'DETAILED');
go 

drop trigger trgDataAU 
go

alter index PK_Data on dbo.data rebuild;
go

select 
	   alloc_unit_type_desc as [AllocUnit],
       index_level, 
       page_count, 
       avg_page_space_used_in_percent as [SpaceUsed], 
       avg_fragmentation_in_percent as [Frag %],
       min_record_size_in_bytes as [MinSize],
       max_record_size_in_bytes as [MaxSize],
       avg_record_size_in_bytes as [Avgsize]
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.Data'),1,null,'DETAILED');
go 

update dbo.data set value = 5;

select 
	   alloc_unit_type_desc as [AllocUnit],
       index_level, 
       page_count, 
       avg_page_space_used_in_percent as [SpaceUsed], 
       avg_fragmentation_in_percent as [Frag %],
       min_record_size_in_bytes as [MinSize],
       max_record_size_in_bytes as [MaxSize],
       avg_record_size_in_bytes as [Avgsize]
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.Data'),1,null,'DETAILED');
go 


/* Delete and page splits */
create trigger trgDataAD 
on dbo.data
after delete
as     
       return;
go

delete from dbo.data 
where ID % 2 = 0;
go

select 
	   alloc_unit_type_desc as [AllocUnit],
       index_level, 
       page_count, 
       avg_page_space_used_in_percent as [SpaceUsed], 
       avg_fragmentation_in_percent as [Frag %],
       min_record_size_in_bytes as [MinSize],
       max_record_size_in_bytes as [MaxSize],
       avg_record_size_in_bytes as [Avgsize]
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.Data'),1,null,'DETAILED');
go 
