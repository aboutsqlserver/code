/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                          Chapter 08. Triggers                            */
/*                        Triggers and Fragmentation                        */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Data'    
)
	drop table dbo.Data
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
;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 rows
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2 ) -- 65,536 rows
,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)
insert into dbo.data(Value)
	select ID
	from Ids
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
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Data'),1,null,'DETAILED')
go 

update dbo.Data set value = 1
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
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Data'),1,null,'DETAILED')
go

create trigger trgDataAU 
on dbo.data
after update
as     
       return
go

update dbo.data set value = 2
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
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Data'),1,null,'DETAILED')
go 


/*** Adding LOB column ***/
alter table dbo.data 
add LobColumn varchar(max) null
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
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Data'),1,null,'DETAILED')
go 

update dbo.data set value = 3
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
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Data'),1,null,'DETAILED')
go 


drop trigger trgDataAU 
go

alter index PK_Data on dbo.data rebuild
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
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Data'),1,null,'DETAILED')
go 

update dbo.data set value = 5
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
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Data'),1,null,'DETAILED')
go 


/* Delete and page splits */
create trigger trgDataAD 
on dbo.data
after delete
as     
       return
go

delete from dbo.data 
where ID % 2 = 0
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
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Data'),1,null,'DETAILED')
go 
