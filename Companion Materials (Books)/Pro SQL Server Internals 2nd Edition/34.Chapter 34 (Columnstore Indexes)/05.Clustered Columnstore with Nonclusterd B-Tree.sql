/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    Chapter 34. Columnstore Indexes                       */
/*       Clustered Columnstore Index with Nonclustered B-Tree indexes       */
/****************************************************************************/

set noexec off
go

use [SqlServerInternals]
go

if convert(int,
		left(
			convert(nvarchar(128), serverproperty('ProductVersion')),
			charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
		)
) < 13 
begin
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

drop table if exists dbo.CCIWithNI
go

create table dbo.CCIWithNI
(
	Col1 int not null,
	Col2 int not null,
	Col3 int not null
);

insert into dbo.CCIWithNI(Col1, Col2, Col3)
values(1,1,1), (2,2,2);

create clustered columnstore index CCI_CCIWithNI on dbo.CCIWithNI; 

insert into dbo.CCIWithNI(Col1, Col2, Col3)
values(100,100,100),(200,200,200);

create nonclustered index IDX_CCIWithNI_Col3 on dbo.CCIWithNI(Col3);
go

-- One compressed row group and one delta store
select object_id, index_id, partition_number, row_group_id
    ,generation, state_desc, total_rows, deleted_rows
from sys.dm_db_column_store_row_group_physical_stats
where object_id =  object_id(N'dbo.CCIWithNI');
go

-- Delta Store and Delete Bitmap only
select ip.object_id, ip.index_id, ip.partition_id, ip.row_group_id, ip.internal_object_type
	,ip.internal_object_type_desc, ip.rows, ip.data_compression_desc, ip.hobt_id, '', '' 
from sys.internal_partitions ip 
where ip.object_id = object_id(N'dbo.CCIWithNI');
go

-- Page allocations for nonclustered B-Tree indexes
select object_id, index_id, partition_id, allocation_unit_type_desc as [Type], is_allocated
	,is_iam_page, page_type, page_type_desc, allocated_page_file_id as [FileId]
    ,allocated_page_page_id as [PageId], rowset_id, allocation_unit_id
from sys.dm_db_database_page_allocations(db_id(), object_id('dbo.CCIWithNI'),2,NULL,'DETAILED')
where is_allocated = 1;
go

dbcc traceon(3604);  -- Redirecting output to console
dbcc page -- Analyzing content of a page
(   'SQLServerInternals'
    ,3      -- FileId
    ,<> 	-- PageId
    ,3      -- Output style
);
go

-- Compression the delta store
alter index CCI_CCIWithNI on dbo.CCIWithNI reorganize 
with (compress_all_row_groups = on);
go

-- Delta store is compressed
select object_id, index_id, partition_number, row_group_id
    ,generation, state_desc, total_rows, deleted_rows 
from sys.dm_db_column_store_row_group_physical_stats
where object_id =  object_id(N'dbo.CCIWithNI');
go

-- Now we have the mapping index
select ip.object_id, ip.index_id, ip.partition_id, ip.row_group_id, ip.internal_object_type
	,ip.internal_object_type_desc, ip.rows, ip.data_compression_desc, ip.hobt_id
from sys.internal_partitions ip 
where ip.object_id = object_id(N'dbo.CCIWithNI');
go

-- Nonclustered B-Tree index did not change
dbcc page -- Analyzing content of a page
(   'SQLServerInternals'
    ,3      -- FileId
    ,<>  	-- PageId
    ,3      -- Output style
);
go

-- "Key Lookup" operator in the execution plan
select Col1, Col2, Col3
from dbo.CCIWithNI with (index = 2)
where Col3 = 2
