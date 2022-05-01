/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                 Chapter 35. Clustered Columnstore Indexes                */
/*                      Delete Bitmap Row Compression                       */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 12 
begin
	raiserror('You should have SQL Server 2014 to execute this script',16,1) with nowait
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on 
		t.schema_id = s.schema_id 
	where s.name = 'dbo' and t.name = 'CCI'
)
	drop table dbo.CCI
go

create table dbo.CCI
(
	Col1 int  not null,
	Col2 varchar(4000) not null,
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,N6(C) as -- 1,048,592 rows
(
	select 0 from N5 as T1 cross join N3 as T2 
	union all 
	select 0 from N3
) 
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N6)
insert into dbo.CCI(Col1,Col2) 
	select ID, 'aaa'
	from IDS
go

create clustered columnstore index IDX_CS_CLUST on dbo.CCI
with (maxdop=1)
go


/*** Deleting all rows */
delete from dbo.CCI
go

/*** Checking allocation units ***/
select object_id, index_id, partition_id
	,allocation_unit_type_desc as [Type]
	,is_allocated,is_iam_page,page_type,page_type_desc
	,allocated_page_file_id as [FileId]
	,allocated_page_page_id as [PageId]
from sys.dm_db_database_page_allocations
	(db_id(), object_id('dbo.CCI'),NULL, NULL, 'DETAILED')
go

/*** Analyzing Data Pages for IN_ROW_DATA allocations based on PID from Previous Script ***/
dbcc traceon(3604)
go

-- REPLACE IDs BELOW
dbcc page
(
	<>	-- Database Id
	,1	-- FileId
	,<>	-- PageId
	,3	-- Output style
) 
go


