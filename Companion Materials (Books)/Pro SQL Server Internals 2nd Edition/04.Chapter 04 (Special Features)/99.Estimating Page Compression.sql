/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*             Chapter 04. Special Indexng and Storage Feautes              */
/*   Estimating Compression space Savings For All Tables in the Database    */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if object_id(N'tempdb..#CompressionData') is not null
	drop table #CompressionData;
if object_id(N'tempdb..#CompressionResults') is not null
	drop table #CompressionResults;
go

create table #CompressionResults
(
	object_name sysname not null,
	schema_name sysname not null,
	index_id int not null,
	partition_number int not null,
	[size_with_current_compressions_setting(KB)] bigint not null,
	[size_with_requested_compressions_setting(KB)] bigint not null,
	[sample_size_with_current_compressions_setting(KB)] bigint not null,
	[sample_size_with_requested_compressions_setting(KB)] bigint not null,
	primary key(schema_name, object_name, index_id, partition_number)
);

create table #CompressionData
(
	ObjectId int not null,
	IndexId int not null,
	PartitionNum int not null,
	TableName sysname not null,
	IndexName sysname null, 
	IndexType sysname not null, 
	CurrentCompression char(5) not null,
	CurrentSizeMB decimal(12,3) not null,
	EstimatedSizeNoneMB decimal(12,3) not null,
	EstimatedSizeRowMB decimal(12,3) not null,
	EstimatedSizePageMB decimal(12,3) not null,

	primary key(TableName, IndexId, PartitionNum)
);

declare
	@object_id int = -1
	,@Table sysname
	,@Index int
	,@Schema sysname
	
while 1 = 1
begin
	select top 1 @object_id = t.object_id, @Schema = s.name, @Table = t.name
	from sys.tables t with (nolock) join sys.schemas s with (nolock) on
		t.schema_id = s.schema_id
	where t.object_id > @object_id and t.is_ms_shipped = 0 -- and t.is_memory_optimized = 0 
	order by t.object_id;
	
	if @@rowcount = 0
		break;

	raiserror('Table %s.%s.',0,1,@Schema, @Table) with nowait;

	truncate table #CompressionResults;
	insert into #CompressionResults
		exec sp_estimate_data_compression_savings
			@schema_name = @Schema
			,@object_name = @Table
			,@index_id = null
			,@partition_number = null 
			,@data_compression = 'none';

	insert into #CompressionData(ObjectId,IndexId,PartitionNum,TableName,IndexName,IndexType,CurrentCompression,
		CurrentSizeMB,EstimatedSizeNoneMB,EstimatedSizeRowMB,EstimatedSizePageMB)
		select 
			@object_id, r.index_id, r.partition_number, @Schema + '.' + @Table, i.name, i.type_desc, p.data_compression_desc, 
			[size_with_current_compressions_setting(KB)] / 1024.0, [size_with_requested_compressions_setting(KB)] / 1024., 0, 0 	
		from 
			#CompressionResults r left join sys.indexes i with (nolock) on 
				i.object_id = @object_id and r.index_id = i.index_id
			join sys.partitions p with (nolock) on 
				p.object_id = @object_id and r.index_id = p.index_id and r.partition_number = p.partition_number
		where
			i.[type] in (0,1,2) and 
			i.is_disabled = 0;

	truncate table #CompressionResults;
	insert into #CompressionResults
		exec sp_estimate_data_compression_savings
			@schema_name = @Schema
			,@object_name = @Table
			,@index_id = null
			,@partition_number = null 
			,@data_compression = 'row';

	update t
	set t.EstimatedSizeRowMB = r.[size_with_requested_compressions_setting(KB)] / 1024.0
	from #CompressionData t join #CompressionResults r on
		t.ObjectId = @object_id and
		t.IndexId = r.index_id and 
		t.PartitionNum = r.partition_number;

	truncate table #CompressionResults;
	insert into #CompressionResults
		exec sp_estimate_data_compression_savings
			@schema_name = @Schema
			,@object_name = @Table
			,@index_id = null
			,@partition_number = null 
			,@data_compression = 'page';

	update t
	set t.EstimatedSizePageMB = r.[size_with_requested_compressions_setting(KB)] / 1024.0
	from #CompressionData t join #CompressionResults r on
		t.ObjectId = @object_id and
		t.IndexId = r.index_id and 
		t.PartitionNum = r.partition_number;

end;

-- Raw data
select * from #CompressionData;

-- On per-index basis. Always take volatility of the data into consideration
;with Data
as
(
	select IndexId, TableName, IndexName, IndexType 
		,sum(CurrentSizeMB) as [Current Size MB]
		,sum(EstimatedSizeNoneMB) as [Estimated Size No Compression MB]
		,sum(EstimatedSizeRowMB) as [Estimated Size Row Compression MB]
		,sum(EstimatedSizePAgeMB) as [Estimated Size Page Compression MB]
	from #CompressionData
	group by IndexId, TableName, IndexName, IndexType
)
select * 
from Data
where [Current Size MB] > 0  
order by 
	[Current Size MB] /  
		case 
			when [Estimated Size Row Compression MB] = 0 
			then [Current Size MB] 
			else [Estimated Size Row Compression MB] 
		end desc;
				 