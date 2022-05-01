/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 07. Designing and Tuning The Indexes               */
/*                         sys.dm_db_index_usage_stats                      */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'UsageDemo') drop table dbo.UsageDemo;
go

create table dbo.UsageDemo
(
	ID int not null,
	Col1 int not null,
	Col2 int not null,
	Placeholder char(8000) null
);

create unique clustered index IDX_CI
on dbo.UsageDemo(ID);

create unique nonclustered index IDX_NCI1
on dbo.UsageDemo(Col1);

create unique nonclustered index IDX_NCI2
on dbo.UsageDemo(Col2);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N3)
insert into dbo.UsageDemo(ID, Col1, Col2)
	select ID, ID, ID
	from IDs;
go

select 
	s.Name + N'.' + t.name as [Table]
	,i.name as [Index] 
	,ius.user_seeks as [Seeks], ius.user_scans as [Scans]
	,ius.user_lookups as [Lookups]
	,ius.user_seeks + ius.user_scans + ius.user_lookups as [Reads]
	,ius.user_updates as [Updates], ius.last_user_seek as [Last Seek]
	,ius.last_user_scan as [Last Scan], ius.last_user_lookup as [Last Lookup]
	,ius.last_user_update as [Last Update]
from 
	sys.tables t join sys.indexes i on
		t.object_id = i.object_id
	join sys.schemas s on 
		t.schema_id = s.schema_id
	left outer join sys.dm_db_index_usage_stats ius on
		ius.database_id = db_id() and
		ius.object_id = i.object_id and 
		ius.index_id = i.index_id
where
	s.name = N'dbo' and t.name = N'UsageDemo'
order by
	s.name, t.name, i.index_id;
go

-- Query 1: CI Seek (Singleton lookup)
select Placeholder from dbo.UsageDemo where ID = 5;

-- Query 2: CI Seek (Range Scan)
select count(*) 
from dbo.UsageDemo with (index=IDX_CI) 
where ID between 2 and 6;

-- Query 3: CI Scan
select count(*) from dbo.UsageDemo with (index=IDX_CI);

-- Query 4: NCI Seek (Singleton lookup + Key Lookup)
select Placeholder from dbo.UsageDemo where Col1 = 5;

-- Query 5: NCI Seek (Range Scan - all data from the table)
select count(*) from dbo.UsageDemo where Col1 > -1;

-- Query 6: NCI Seek (Range Scan + Key Lookup)
select sum(Col2) 
from dbo.UsageDemo with (index = IDX_NCI1) 
where Col1 between 1 and 5;

-- Queries 7-8: Updates
update dbo.UsageDemo set Col2 = -3 where Col1 = 3;
update dbo.UsageDemo set Col2 = -4 where Col1 = 4;
go

select 
	s.Name + N'.' + t.name as [Table]
	,i.name as [Index] 
	,ius.user_seeks as [Seeks], ius.user_scans as [Scans]
	,ius.user_lookups as [Lookups]
	,ius.user_seeks + ius.user_scans + ius.user_lookups as [Reads]
	,ius.user_updates as [Updates], ius.last_user_seek as [Last Seek]
	,ius.last_user_scan as [Last Scan], ius.last_user_lookup as [Last Lookup]
	,ius.last_user_update as [Last Update]
from 
	sys.tables t join sys.indexes i on
		t.object_id = i.object_id
	join sys.schemas s on 
		t.schema_id = s.schema_id
	left outer join sys.dm_db_index_usage_stats ius on
		ius.database_id = db_id() and
		ius.object_id = i.object_id and 
		ius.index_id = i.index_id
where
	s.name = N'dbo' and t.name = N'UsageDemo'
order by
	s.name, t.name, i.index_id;
go