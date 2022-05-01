/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*        Appendix C: Analyzing the States of Checkpoint File Pairs         */
/*                        02.Analyzing CFPs states                          */
/****************************************************************************/

set noexec off
go

set nocount on
go

use InMemoryOLTP2014_AppendixC
go

if exists(select * from sys.dm_db_xtp_checkpoint_files)
begin
	raiserror('Please recreate the database using 01.DB Creation script',16,1) with nowait
	set noexec on
end
go

/* Disabling automatic merge. DO NOT RUN IN PRODUCTION! */
dbcc traceon(9851,-1)
go



-- Empty result set - there is no memory-optimized objects in the database
select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,inserted_row_count
	,deleted_row_count
	,relative_file_path
from sys.dm_db_xtp_checkpoint_files
order by
	state, file_type
go

create table dbo.HKData
(
    ID int not null,
    Placeholder char(8000) not null,

    constraint PK_HKData
    primary key nonclustered hash(ID) 
    with (bucket_count=10000),
)
with (memory_optimized=on, durability=schema_and_data)  
go

-- PRECREATED/UNDER CONSTRUCTION FILES
select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,inserted_row_count
	,deleted_row_count
	,relative_file_path
from sys.dm_db_xtp_checkpoint_files
order by
	state, file_type
go

-- Populating table with the data
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N5)
insert into dbo.HKData(Id, Placeholder)
    select Id, Replicate('0',8000)
    from ids
    where Id <= 1000;
go

-- UNDER CONSTRUCTION FILES
select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,inserted_row_count
	,deleted_row_count
	,relative_file_path
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, file_type
go

checkpoint
go

-- UNDER CONSTRUCTION becomes ACTIVE
select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,inserted_row_count
	,deleted_row_count
	,relative_file_path
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, file_type
go

-- Adding more data
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N5)
insert into dbo.HKData(Id, Placeholder)
    select 1000 + Id, Replicate('0',8000)
    from ids
    where Id <= 1000;
go

-- ACTIVE + UNDER CONSTRUCTION FILES
select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,inserted_row_count
	,deleted_row_count
	,relative_file_path
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, file_type
go

checkpoint
go

-- UNDER CONSTRUCTION becomes ACTIVE
select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,inserted_row_count
	,deleted_row_count
	,relative_file_path
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, file_type
go


-- Deleting 66.7% of the data
delete from dbo.HKData
where ID % 3 <> 0;
go

select 
	data.checkpoint_file_id 
	,data.state_desc
	,data.lower_bound_tsn
	,data.upper_bound_tsn
	,data.file_size_in_bytes
	,data.file_size_used_in_bytes
	,data.inserted_row_count
	,delta.deleted_row_count
	,convert(decimal(5,2),100. - 100. * delta.deleted_row_count / data.inserted_row_count) 
		as [% Full] 
from 
	sys.dm_db_xtp_checkpoint_files data join
		sys.dm_db_xtp_checkpoint_files delta on
			data.checkpoint_pair_file_id = delta.checkpoint_file_id
where
	data.file_type_desc = 'DATA' and
	data.state_desc <> 'PRECREATED'
go


-- Forcing manual merge and checking merge request status
-- Make sure to specify correct upper and lower bounds for the merge
exec sys.sp_xtp_merge_checkpoint_files 
	@database_name = 'InMemoryOLTP2014_AppendixC'
	,@transaction_lower_bound = 1
	,@transaction_upper_bound = 8;

select 
	request_state_desc
	,destination_file_id
	,lower_bound_tsn
	,upper_bound_tsn
	,source0_file_id
	,source1_file_id
from sys.dm_db_xtp_merge_requests;
go

-- Wait several seconds

-- ACTIVE + MERGE TARGET
select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,inserted_row_count
	,deleted_row_count
	,relative_file_path
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, file_type
go

checkpoint
go

-- MERGED SOURCE
select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,inserted_row_count
	,deleted_row_count
	,relative_file_path
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, file_type
go

checkpoint
go

-- REQUIRED FOR BACKUP/HA
select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,inserted_row_count
	,deleted_row_count
	,relative_file_path
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, file_type
go

-- Backing up log. There is the chance that you'll need to do 
-- Backup/Checkpoint multiple times to force CFPs to GC state
backup log InMemoryOLTP2014_AppendixC
to disk = N'InMemoryOLTP2014_AppendixC.bak'
with noformat, noinit, name = 'AppendixD - Log', compression
go
 
checkpoint
go

-- IN TRANSITION TO TOMBSTONE
select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,inserted_row_count
	,deleted_row_count
	,relative_file_path
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, file_type
go

exec sys.sp_xtp_checkpoint_force_garbage_collection
go

select 
	checkpoint_file_id 
	,checkpoint_pair_file_id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,inserted_row_count
	,deleted_row_count
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, file_type
go

-- Make sure to re-enable automatic merge!
dbcc traceoff(9851,-1)
go
