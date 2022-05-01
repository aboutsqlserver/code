/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    Chapter 34. Columnstore Indexes                       */
/*               Updateable nonclustered columnstore indexes                */
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

drop table if exists dbo.NonclusteredColumnstore
go

create table dbo.NonclusteredColumnstore
(
	Col1 int not null,
	Col2 int not null,
	Col3 int not null,
	constraint PK_NonclusteredColumnstore
	primary key clustered(Col1, Col2)
)
go

insert into dbo.NonclusteredColumnstore(Col1, Col2, Col3)
values(1,10,100), (2, 20, 200), (3, 30, 300)

create nonclustered columnstore index NCI_NonclusteredColumnstore
on dbo.NonclusteredColumnstore(Col2, Col3)
with (maxdop = 1)
go

delete from dbo.NonclusteredColumnstore where Col1 = 3
go

-- One compressed rowgroup
select object_id, index_id, partition_number, row_group_id
    ,generation, state_desc, total_rows, deleted_rows 
from sys.dm_db_column_store_row_group_physical_stats
where object_id =  object_id(N'dbo.NonclusteredColumnstore');
go

-- Delete bitmap + 2 delete buffers
select ip.object_id, ip.index_id, ip.partition_id, ip.row_group_id
    ,ip.internal_object_type, ip.internal_object_type_desc, ip.rows
	,ip.data_compression_desc, ip.hobt_id
from sys.internal_partitions ip 
where ip.object_id = object_id(N'dbo.NonclusteredColumnstore');
go

select object_id, index_id, partition_id, allocation_unit_type_desc as [Type], is_allocated
	,is_iam_page, page_type, page_type_desc, allocated_page_file_id as [FileId]
    ,allocated_page_page_id as [PageId], rowset_id, allocation_unit_id, '', ''
from sys.dm_db_database_page_allocations
            (db_id(),object_id('dbo.NonclusteredColumnstore'),null,null,'DETAILED')
where is_allocated = 1 and rowset_id in (<>); -- Use hobt_id of delete buffer from sys.internal_partitions
go

dbcc traceon(3604);  -- Redirecting output to console
dbcc page -- Analyzing content of a page
(   'SQLServerInternals'       -- Database Id
    ,3		-- FileId
    ,<>		-- PageId
    ,3		-- Output style
);
go
 