/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*               Chapter 06. Designing and Tuning The Indexes               */
/*                         Non-unique Clustered Indexes                     */
/****************************************************************************/

use [SqlServerInternals]
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'UniqueCI'    
)
	drop table dbo.UniqueCI
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'NonUniqueCINoDups'    
)
	drop table dbo.NonUniqueCINoDups
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'NonUniqueCIDups'    
)
	drop table dbo.NonUniqueCIDups
go

create table dbo.UniqueCI
(
	KeyValue int not null,
	ID int not null,
	Data char(986) null,
	VarData varchar(32) not null
		constraint DEF_UniqueCI_VarData
		default 'Data'
);

create unique clustered index IDX_UniqueCI_KeyValue
on dbo.UniqueCI(KeyValue);

create table dbo.NonUniqueCINoDups
(
	KeyValue int not null,
	ID int not null,
	Data char(986) null,
	VarData varchar(32) not null
		constraint DEF_NonUniqueCINoDups_VarData
		default 'Data'
);

create /*unique*/ clustered index IDX_NonUniqueCINoDups_KeyValue
on dbo.NonUniqueCINoDups(KeyValue);

create table dbo.NonUniqueCIDups
(
	KeyValue int not null,
	ID int not null,
	Data char(986) null,
	VarData varchar(32) not null
		constraint DEF_NonUniqueCIDups_VarData
		default 'Data'
);

create /*unique*/ clustered index IDX_NonUniqueCIDups_KeyValue
on dbo.NonUniqueCIDups(KeyValue);

-- Populating data
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.UniqueCI(KeyValue, ID)
	select ID, ID
	from IDs;
	
insert into dbo.NonUniqueCINoDups(KeyValue, ID)
	select KeyValue, ID
	from dbo.UniqueCI;	

insert into dbo.NonUniqueCIDups(KeyValue, ID)
	select KeyValue % 10, ID
	from dbo.UniqueCI;	
go

/*** Checking CI row size ***/
select index_level, page_count, min_record_size_in_bytes as [min row size]
	,max_record_size_in_bytes as [max row size]
	,avg_record_size_in_bytes as [avg row size]
from sys.dm_db_index_physical_stats
(db_id(), object_id(N'dbo.UniqueCI'), 1, null , 'DETAILED')

select index_level, page_count, min_record_size_in_bytes as [min row size]
	,max_record_size_in_bytes as [max row size]
	,avg_record_size_in_bytes as [avg row size]
from sys.dm_db_index_physical_stats
(db_id(), object_id(N'dbo.NonUniqueCINoDups'), 1, null , 'DETAILED')

select index_level, page_count, min_record_size_in_bytes as [min row size]
	,max_record_size_in_bytes as [max row size]
	,avg_record_size_in_bytes as [avg row size]
from sys.dm_db_index_physical_stats
(db_id(), object_id(N'dbo.NonUniqueCIDups'), 1, null , 'DETAILED')
go

/*** Checking NCI row size ***/
create nonclustered index IDX_UniqueCI_ID
on dbo.UniqueCI(ID);

create nonclustered index IDX_NonUniqueCINoDups_ID
on dbo.NonUniqueCINoDups(ID);

create nonclustered index IDX_NonUniqueCIDups_ID
on dbo.NonUniqueCIDups(ID);

select index_level, page_count, min_record_size_in_bytes as [min row size]
	,max_record_size_in_bytes as [max row size]
	,avg_record_size_in_bytes as [avg row size]
from sys.dm_db_index_physical_stats
(db_id(), object_id(N'dbo.UniqueCI'), 2, null , 'DETAILED')

select index_level, page_count, min_record_size_in_bytes as [min row size]
	,max_record_size_in_bytes as [max row size]
	,avg_record_size_in_bytes as [avg row size]
from sys.dm_db_index_physical_stats
(db_id(), object_id(N'dbo.NonUniqueCINoDups'), 2, null , 'DETAILED')

select index_level, page_count, min_record_size_in_bytes as [min row size]
	,max_record_size_in_bytes as [max row size]
	,avg_record_size_in_bytes as [avg row size]
from sys.dm_db_index_physical_stats
(db_id(), object_id(N'dbo.NonUniqueCIDups'), 2, null , 'DETAILED')
go

