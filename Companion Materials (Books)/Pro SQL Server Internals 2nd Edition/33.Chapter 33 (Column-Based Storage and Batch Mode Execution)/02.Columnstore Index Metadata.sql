/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*          Chapter 33. Column-Based Storage and Batch Mode Execution       */
/*                        Columnstore Index Metadata                        */
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
	) < 11 
begin
	raiserror('You should have SQL Server 2012+ to execute this script',16,1) with nowait;
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

if not exists
(
	select * 
	from sys.tables t join sys.schemas s on 
		t.schema_id = s.schema_id 
	where s.name = 'dbo' and t.name = 'FactSales')
begin
	raiserror('Create dbo.FactSales table with "01.Batch Mode Execution.sql" script',16,1);
	set noexec on
end
go

/*** Allocation Units ***/
select i.name as [Index], p.index_id
	,p.partition_number as [Partition]
	,p.data_compression_desc as [Compression] 
	,u.type_desc, u.total_pages
from 
	sys.partitions p join sys.allocation_units u on
		p.partition_id = u.container_id
	join sys.indexes i on
		p.object_id = i.object_id and 
		p.index_id = i.index_id
where
	p.object_id = object_id(N'dbo.FactSales');
go

/*** Segments ***/
select p.partition_number as [partition], c.name as [column]
	,s.column_id, s.segment_id, p.data_compression_desc as [compression]
	,s.version, s.encoding_type, s.row_count, s.has_nulls, s.magnitude
	,s.primary_dictionary_id, s.secondary_dictionary_id, s.min_data_id
	,s.max_data_id, s.null_value
	,convert(decimal(12,3),s.on_disk_size / 1024. / 1024.)  as [Size MB]
from 
	sys.column_store_segments s join sys.partitions p on
		p.partition_id = s.partition_id
	join sys.indexes i on
		p.object_id = i.object_id
	left join sys.index_columns ic on
		i.index_id = ic.index_id and
		i.object_id = ic.object_id and
		s.column_id = ic.index_column_id
	left join sys.columns c on
		ic.column_id = c.column_id and
		ic.object_id = c.object_id
where
	i.name = 'IDX_FactSales_ColumnStore'
order by
	p.partition_number, s.segment_id, s.column_id;
go

/*** Dictionaries ***/
select p.partition_number as [partition], c.name as [column]
	,d.column_id, d.dictionary_id, d.version, d.type, d.last_id
	,d.entry_count
	,convert(decimal(12,3),d.on_disk_size / 1024. / 1024.)  as [Size MB]
from 
	sys.column_store_dictionaries d join sys.partitions p on
		p.partition_id = d.partition_id
	join sys.indexes i on
		p.object_id = i.object_id
	left join sys.index_columns ic on
		i.index_id = ic.index_id and
		i.object_id = ic.object_id and
		d.column_id = ic.index_column_id
	left join sys.columns c on
		ic.column_id = c.column_id and
		ic.object_id = c.object_id
where
	i.name = 'IDX_FactSales_ColumnStore'
order by
	p.partition_number, d.column_id;
go

-- You can see other columnstore-related DMVs in Chapter 34 scripts