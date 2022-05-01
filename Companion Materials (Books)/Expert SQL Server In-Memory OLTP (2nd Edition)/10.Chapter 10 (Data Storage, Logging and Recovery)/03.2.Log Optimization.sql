/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 10: Data Storage, Logging and Recovery              */
/*                           03.Log Optimization                            */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016_Ch10
go

drop table if exists dbo.AlterLogging;

create table dbo.AlterLogging
(
	Id int not null
		constraint PK_AlterLogging
		primary key nonclustered,
	IntCol int not null,
	CharCol char(8000) not null
)
with (memory_optimized = on, durability = schema_and_data)
go

-- Populating table with the data
-- You may want to reduce the number of rows if you have less than 24GB of RAM
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,N6(C) as (select 0 from N5 as t1 cross join N3 as t2) -- 1,048,576 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N5) -- 65,536 rows only - for small VMs
insert into dbo.AlterLogging(Id, IntCol, CharCol)
    select Id, Id, Replicate('0',8000)
    from Ids;

checkpoint;
go


select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes / 1024 / 1024 as [size MB]
	,file_size_used_in_bytes / 1024 / 1024 
		as [size used MB]
	,logical_row_count
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	lower_bound_tsn, file_type
go

select 
    convert(decimal(9,3),sum(file_size_in_bytes) / 1024. / 1024) 
        as [Checkpoint Files Size MB]
    ,convert(decimal(9,3),sum(file_size_used_in_bytes) / 1024. / 1024)
        as [Checkpoint Files Size Used MB]
from 
    sys.dm_db_xtp_checkpoint_files;

select 
    name as [FileName]
    ,convert(decimal(9,3),size / 128.)
	    as [Log Size MB]
    ,convert(decimal(9,3),fileproperty(name,'SpaceUsed') / 128.)
        as [Log Size Used MB]
from sys.database_files
where name = 'InMemoryOLTP2016_Ch10_log';
go


alter table dbo.AlterLogging add IntCol2 int 
go

checkpoint
go

select 
    convert(decimal(9,3),sum(file_size_in_bytes) / 1024. / 1024) 
        as [Checkpoint Files Size MB]
    ,convert(decimal(9,3),sum(file_size_used_in_bytes) / 1024. / 1024)
        as [Checkpoint Files Size Used MB]
from 
    sys.dm_db_xtp_checkpoint_files;

select 
    name as [FileName]
    ,convert(decimal(9,3),size / 128.)
	    as [Log Size MB]
    ,convert(decimal(9,3),fileproperty(name,'SpaceUsed') / 128.)
        as [Log Size Used MB]
from sys.database_files
where name = 'InMemoryOLTP2016_Ch10_log';
go


alter table dbo.AlterLogging add LOB varchar(max);
go

checkpoint
go

select 
	sum(file_size_in_bytes) / 1024 / 1024 as [size MB]
	,sum(file_size_used_in_bytes) / 1024 / 1024 
		as [size used MB]
from 
	sys.dm_db_xtp_checkpoint_files;
go

select 
	name as [FileName]
	,size / 128.0 as [File Size MB]
	,convert(int,fileproperty(name,'SpaceUsed')) / 128.0 
		as [Used MB]
from sys.database_files
where name = 'InMemoryOLTP2016_Ch10_log';
go
