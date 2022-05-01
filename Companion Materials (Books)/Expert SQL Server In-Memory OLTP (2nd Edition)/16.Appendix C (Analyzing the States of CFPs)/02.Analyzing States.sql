/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
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

use InMemoryOLTP2016_AppendixC
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
    checkpoint_file_Id 
    ,checkpoint_pair_file_Id
    ,file_type_desc
    ,state_desc
    ,file_size_in_bytes / 1024 / 1024 
	    as [size MB]
    ,relative_file_path
from 
    sys.dm_db_xtp_checkpoint_files;
go

create table dbo.HKData
(
    Id int not null,
    Placeholder char(8000) not null,

    constraint PK_HKData
    primary key nonclustered hash(Id) 
    with (bucket_count=8192),
)
with (memory_optimized=on, durability=schema_and_data)  
go

waitfor delay '00:00:05.000';
go

-- PRECREATED FILES
select 
    checkpoint_file_Id 
    ,checkpoint_pair_file_Id
    ,file_type_desc
    ,state_desc
    ,file_size_in_bytes / 1024 / 1024 
	    as [size MB]
    ,relative_file_path
from 
    sys.dm_db_xtp_checkpoint_files
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
    from Ids
    where Id <= 1000;

insert into dbo.T values(0);

waitfor delay '00:00:03.000';

select 
	checkpoint_file_Id 
	,checkpoint_pair_file_Id
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
	file_type, lower_bound_tsn
go


checkpoint
go

-- UNDER CONSTRUCTION becomes ACTIVE
select 
	checkpoint_file_Id 
	,checkpoint_pair_file_Id
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


-- Adding more data
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N5)
insert into dbo.HKData(Id, Placeholder)
    select 1000 + Id, Replicate('0',8000)
    from Ids
    where Id <= 1000;
go

insert into dbo.T values(1);

waitfor delay '00:00:03.000';

-- ACTIVE + UNDER CONSTRUCTION FILES
select 
	checkpoint_file_Id 
	,checkpoint_pair_file_Id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes / 1024 / 1024 as [size MB]
	,file_size_used_in_bytes 
	,logical_row_count
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	lower_bound_tsn, file_type
go

checkpoint
go

-- UNDER CONSTRUCTION becomes ACTIVE
select 
	checkpoint_file_Id 
	,checkpoint_pair_file_Id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes / 1024 / 1024 as [size MB]
	,file_size_used_in_bytes 
	,logical_row_count
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	lower_bound_tsn, file_type
go

-- Deleting 99% of the data
delete from dbo.HKData
where Id % 100 <> 0;
go

checkpoint
go

-- Look at logical_row_count and % fill
select 
	data.checkpoint_file_Id 
	,data.state_desc
	,data.lower_bound_tsn
	,data.upper_bound_tsn
	,data.file_size_in_bytes
	,data.file_size_used_in_bytes
	,data.logical_row_count
	,delta.logical_row_count
	,convert(decimal(5,2),
		iif(data.logical_row_count = 0,0,
	        100. - 100. * delta.logical_row_count / 
		         data.logical_row_count)) 
		as [% Full] 
from 
	sys.dm_db_xtp_checkpoint_files data join
		sys.dm_db_xtp_checkpoint_files delta on
			data.checkpoint_pair_file_Id = delta.checkpoint_file_Id
where
	data.file_type_desc = 'DATA' and
	data.state_desc <> 'PRECREATED'
order by 
	data.lower_bound_tsn
go


-- Enabling automatic merge
dbcc traceoff(9851,-1)
go


checkpoint 
go

-- Merge process started
select 
	checkpoint_file_Id 
	,checkpoint_pair_file_Id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes / 1024 / 1024 as [size MB]
	,file_size_used_in_bytes 
	,logical_row_count
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, lower_bound_tsn
go

waitfor delay '00:00:30.000';

checkpoint
go

-- Merge completed
select 
	checkpoint_file_Id 
	,checkpoint_pair_file_Id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,logical_row_count
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, lower_bound_tsn
go

-- Backing up log. 
backup log InMemoryOLTP2016_AppendixC
to disk = N'InMemoryOLTP2016_AppendixC.bak'
with noformat, noinit, name = 'AppendixC - Log', compression
go

checkpoint
go

-- WAITING FOR LOG TRUNCATION
select 
	checkpoint_file_Id 
	,checkpoint_pair_file_Id
	,file_type_desc
	,state_desc
	,lower_bound_tsn
	,upper_bound_tsn
	,file_size_in_bytes
	,file_size_used_in_bytes
	,logical_row_count
from 
	sys.dm_db_xtp_checkpoint_files
where
	state_desc <> 'PRECREATED'
order by
	state, lower_bound_tsn
go