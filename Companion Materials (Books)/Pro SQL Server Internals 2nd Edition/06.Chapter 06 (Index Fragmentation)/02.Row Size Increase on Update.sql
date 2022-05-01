/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 06. Index Fragmentation                     */
/*                   Insert/Update and Row Size Increase                    */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Positions') drop table dbo.Positions;
go

create table dbo.Positions
(
	DeviceId int not null,
	ATime datetime not null,
	Latitude decimal(9,6) not null,
	Longitude decimal(9,6) not null,
	Address nvarchar(200) null,
	Placeholder char(100) null,
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.Positions(DeviceId, ATime, Latitude, Longitude)
	select 
		ID % 100 /*DeviceId*/ 
		,dateadd(minute, -(ID % 657), getutcdate()) /*ATime*/
		,0 /*Latitude - just dummy value*/
		,0 /*Longitude - just dummy value*/
	from IDs;

create unique clustered index IDX_Postitions_DeviceId_ATime
on dbo.Positions(DeviceId, ATime);

select index_level, page_count, avg_page_space_used_in_percent, avg_fragmentation_in_percent
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Positions'),1,null,'DETAILED');
go

 update dbo.Positions set Address = N'Position address';

select index_level, page_count, avg_page_space_used_in_percent, avg_fragmentation_in_percent
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'dbo.Positions'),1,null,'DETAILED');
go

/*** Workaround 1 ***/
select avg(datalength(Address)) as [Avg Address Size] from dbo.Positions ;
go

drop table dbo.Positions
go

create table dbo.Positions
(
	DeviceId int not null,
	ATime datetime not null,
	Latitude decimal(9,6) not null,
	Longitude decimal(9,6) not null,
	Address nvarchar(200) null,
	Placeholder char(100) null,
	Dummy varbinary(32)
);
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.Positions(DeviceId, ATime, Latitude, Longitude, Address)
	select 
		ID % 100 /*DeviceId*/ 
		,dateadd(minute, -(ID % 657), getutcdate()) /*ATime*/
		,0 /*Latitude - just dummy value*/
		,0 /*Longitude - just dummy value*/
		,replicate(N' ',16) /*Address - adding string of 16 space characters*/
	from IDs;

create unique clustered index IDX_Postitions_DeviceId_ATime
on dbo.Positions(DeviceId, ATime);
go

update dbo.Positions set Address = N'Position address';

select index_level, page_count, avg_page_space_used_in_percent, avg_fragmentation_in_percent
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'Positions'),1,null,'DETAILED');
go


/*** Workaround 2 ***/
drop table dbo.Positions
go

create table dbo.Positions
(
	DeviceId int not null,
	ATime datetime not null,
	Latitude decimal(9,6) not null,
	Longitude decimal(9,6) not null,
	Address nvarchar(200) null,
	Placeholder char(100) null,
	Dummy varbinary(32)
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.Positions(DeviceId, ATime, Latitude, Longitude, Dummy)
	select 
		ID % 100 /*DeviceId*/ 
		,dateadd(minute, -(ID % 657), getutcdate()) /*ATime*/
		,0 /*Latitude - just dummy value*/
		,0 /*Longitude - just dummy value*/
		,convert(varbinary(32),replicate('0',32)) /*Dummy column to reserve the space*/
	from IDs;

create unique clustered index IDX_Postitions_DeviceId_ATime
on dbo.Positions(DeviceId, ATime);
go

update dbo.Positions 
set 
	Address = N'Position address'
	,Dummy = null;

select index_level, page_count, avg_page_space_used_in_percent, avg_fragmentation_in_percent
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'Positions'),1,null,'DETAILED');
go
