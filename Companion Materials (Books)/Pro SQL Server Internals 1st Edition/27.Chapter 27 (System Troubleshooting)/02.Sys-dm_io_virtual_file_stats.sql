/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                   Chapter 27. System Troubleshooting                     */
/*                      Sys.dm_io_virtual_file_stats                        */
/****************************************************************************/


/*** Using sys.dm_io_virtual_file_stats view ***/
select 
	fs.database_id as [DB ID]
	,fs.file_id as [File Id]
	,mf.name as [File Name]
	,mf.physical_name as [File Path]
	,mf.type_desc as [Type]
	,fs.sample_ms as [Time]
	,fs.num_of_reads as [Reads]
	,fs.num_of_bytes_read as [Read Bytes]
	,fs.num_of_writes as [Writes]
	,fs.num_of_bytes_written as [Written Bytes]
	,fs.num_of_reads + fs.num_of_writes as [IO Count]
	,convert(decimal(5,2),100.0 * fs.num_of_bytes_read / 
		(fs.num_of_bytes_read + fs.num_of_bytes_written)) as [Read %]
	,convert(decimal(5,2),100.0 * fs.num_of_bytes_written / 
		(fs.num_of_bytes_read + fs.num_of_bytes_written)) as [Write %]
	,fs.io_stall_read_ms as [Read Stall]
	,fs.io_stall_write_ms as [Write Stall]
	,case when fs.num_of_reads = 0 
		then 0.000
		else convert(decimal(12,3),1.0 * 
			fs.io_stall_read_ms / fs.num_of_reads) 
	end as [Avg Read Stall] 
	,case when fs.num_of_writes = 0 
		then 0.000
		else convert(decimal(12,3),1.0 * 
			fs.io_stall_write_ms / fs.num_of_writes) 
	end as [Avg Write Stall] 
from 
	sys.dm_io_virtual_file_stats(null,null) fs join 
		sys.master_files mf with (nolock) on
			fs.database_id = mf.database_id and
			fs.file_id = mf.file_id     
	join sys.databases d with (nolock) on
		d.database_id = fs.database_id  
where
	fs.num_of_reads + fs.num_of_writes > 0
option (recompile)
go

/*** Get Snapshot of I/O activity ***/
create table #Snapshot
(
	database_id smallint not null,
	file_id smallint not null,
	num_of_reads bigint not null,
	num_of_bytes_read bigint not null,
	io_stall_read_ms bigint not null,
	num_of_writes bigint not null,
	num_of_bytes_written bigint not null,
	io_stall_write_ms bigint not null
);

insert into #Snapshot(database_id,file_id,num_of_reads,num_of_bytes_read
	,io_stall_read_ms,num_of_writes,num_of_bytes_written
	,io_stall_write_ms)
	select database_id,file_id,num_of_reads,num_of_bytes_read
		,io_stall_read_ms,num_of_writes,num_of_bytes_written
		,io_stall_write_ms
	from sys.dm_io_virtual_file_stats(NULL,NULL)
option (recompile);

-- Set test interval (1 minute)
waitfor delay '00:01:00.000';

;with Stats(db_id, file_id, Reads, ReadBytes, Writes
	,WrittenBytes, ReadStall, WriteStall)
as
(
	select
		s.database_id, s.file_id
		,fs.num_of_reads - s.num_of_reads
		,fs.num_of_bytes_read - s.num_of_bytes_read
		,fs.num_of_writes - s.num_of_writes
		,fs.num_of_bytes_written - s.num_of_bytes_written
		,fs.io_stall_read_ms - s.io_stall_read_ms
		,fs.io_stall_write_ms - s.io_stall_write_ms
	from
		#Snapshot s join sys.dm_io_virtual_file_stats(null, null) fs on
			s.database_id = fs.database_id and s.file_id = fs.file_id
)
select
	s.db_id as [DB ID], d.name as [Database]
	,mf.name as [File Name], mf.physical_name as [File Path]
	,mf.type_desc as [Type], s.Reads 
	,convert(decimal(12,3), s.ReadBytes / 1048576.) as [Read MB]
	,convert(decimal(12,3), s.WrittenBytes / 1048576.) as [Written MB]
	,s.Writes, s.Reads + s.Writes as [IO Count]
	,convert(decimal(5,2),100.0 * s.ReadBytes / 
			(s.ReadBytes + s.WrittenBytes)) as [Read %]
	,convert(decimal(5,2),100.0 * s.WrittenBytes / 
			(s.ReadBytes + s.WrittenBytes)) as [Write %]
	,s.ReadStall as [Read Stall]
	,s.WriteStall as [Write Stall]
	,case when s.Reads = 0 
		then 0.000
		else convert(decimal(12,3),1.0 * s.ReadStall / s.Reads) 
	end as [Avg Read Stall] 
	,case when s.Writes = 0 
		then 0.000
		else convert(decimal(12,3),1.0 * s.WriteStall / s.Writes) 
	end as [Avg Write Stall] 
from
	Stats s join sys.master_files mf with (nolock) on
		s.db_id = mf.database_id and
		s.file_id = mf.file_id
	join sys.databases d with (nolock) on 
		s.db_id = d.database_id  
where
	s.Reads + s.Writes > 0
order by
	s.db_id, s.file_id
option (recompile);

drop table #Snapshot
go


