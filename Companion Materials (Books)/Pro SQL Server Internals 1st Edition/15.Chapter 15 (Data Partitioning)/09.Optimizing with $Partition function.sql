/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                      Chapter 15. Data Partitioning                       */
/*               Query Optimization with $Partition function                */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*			This script requires Enterprise Edition of SQL Server.			*/
/****************************************************************************/

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

if exists(
	select *
	from sys.views v join sys.schemas s on
		v.schema_id = s.schema_id
	where
		v.name = 'Data' and s.name = 'dbo'
)
	drop view dbo.Data
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'Data' and s.name = 'dbo'
)
	drop table dbo.Data
go


if exists(
	select *
	from sys.partition_schemes 
	where name = 'psData2'
)
	drop partition scheme psData2
go


if exists(
	select *
	from sys.partition_functions
	where name = 'pfData2'
)
	drop partition function pfData2
go


/*** Non-partitioned Table ***/
create table dbo.Data
(
	Id int not null,
	DateCreated datetime not null
		constraint DEF_Data_DateCreated
		default getutcdate(),
	DateModified datetime not null
		constraint DEF_Data_DateModified
		default getutcdate(),
	Placeholder char(500) null
);

create unique clustered index IDX_Data_Id 
on dbo.Data(DateCreated, Id);

create unique nonclustered index IDX_Data_DateModified_Id
on dbo.Data(DateModified, Id);
go

declare @StartDate datetime 

select @StartDate = '2014-01-01';

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,N6(C) as (select 0 from N5 as T1 cross join N2 as T2 cross join N1 as T3) -- 524,288 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N6)
insert into dbo.Data(ID, DateCreated, DateModified)
	select ID, dateadd(second,35 * Id,@StartDate),
	   case
		  when ID % 10 = 0 
		  then dateadd(second,   
				24 * 60 * 60 * (ID % 31) + 11200 + ID % 59 + 35 * ID,
				@StartDate)
		  else dateadd(second,35 * ID,@StartDate)
	   end
	from IDs;
go

-- Enable "Include Execution Plan"

declare 
	@LastDateModified datetime 

select @LastDateModified = '2014-05-25'

set statistics io on

select top 100 Id, DateCreated, DateModified, PlaceHolder
from dbo.Data
where DateModified > @LastDateModified
order by DateModified, Id

set statistics io off
go

/*** Let's partition the table ***/
drop index IDX_Data_DateModified_Id on dbo.Data;
drop index IDX_Data_Id ON dbo.data;

create partition function pfData2(datetime)
as range right for values 
('2014-02-01', '2014-03-01','2014-04-01','2014-05-01'
,'2014-06-01','2014-07-01','2014-08-01')
go

create partition scheme psData2 
as partition pfData2
all to ([FASTSTORAGE])
go

create unique clustered index IDX_Data_DateCreated_Id
on dbo.Data(DateCreated,ID)
on psData2(DateCreated)
go
	
create unique nonclustered index IDX_Data_DateModified_Id_DateCreated
on dbo.Data(DateModified, ID, DateCreated)
on psData2(DateCreated)
go


-- Clustered Index Scan
declare 
	@LastDateModified datetime 

select @LastDateModified = '2014-05-25'

set statistics io on

select top 100 Id, DateCreated, DateModified, PlaceHolder
from dbo.Data
where DateModified > @LastDateModified
order by DateModified, Id

set statistics io off
go



-- Even less efficient
declare 
	@LastDateModified datetime 

select @LastDateModified = '2014-05-25'

set statistics io on

select top 100 Id, DateCreated, DateModified, PlaceHolder
from dbo.Data with (index=IDX_Data_DateModified_Id_DateCreated)
where DateModified > @LastDateModified
order by DateModified, Id

set statistics io off
go




-- Single partition scope
declare 
	@LastDateModified datetime 

select @LastDateModified = '2014-05-25'

set statistics io on

select top 100 Id, DateCreated, DateModified, PlaceHolder
from dbo.Data 
where DateModified > @LastDateModified and $partition.pfData2(DateCreated) = 5
order by DateModified, Id

set statistics io off
go



-- Optimized Version
declare 
	@LastDateModified datetime 
	,@BoundaryValuesCount int 

select @LastDateModified = '2014-05-25'
	
-- Getting number of boundary values in partition function
select @BoundaryValuesCount = max(boundary_id) 
from sys.partition_functions pf join  
	sys.partition_range_values prf on
		pf.function_id = prf.function_id
where pf.name = 'pfData2'

set statistics io on

;with Partitions(PartitionNum)
as
(
	select 1
	union all
	select PartitionNum + 1
	from Partitions
	where PartitionNum <= @BoundaryValuesCount
)
,Steps1and2(Id, DateCreated, DateModified)
as 
(
	select top 100 PartData.ID, PartData.DateCreated, PartData.DateModified
	from Partitions p
		cross apply
		( -- Step 1 - runs once per partition 
			select top 100 Id, DateCreated, DateModified
			from dbo.Data
			where 
				DateModified > @LastDateModified and
				$Partition.pfData2(DateCreated) = 
					p.PartitionNum
			order by DateModified, ID
		) PartData
	order by PartData.DateModified, PartData.Id
)
-- Step 3 - CI seek as Key Lookup operation
select s.Id, s.DateCreated, s.DateModified, d.Placeholder
from Steps1and2 s join dbo.Data d on	
	d.Id = s.Id and s.DateCreated = d.DateCreated
order by s.DateModified, s.Id

set statistics io off
go


-- Using Temporary Table to Improve Cardinality Estimations
declare 
	@LastDateModified datetime 
	,@BoundaryValuesCount int 

select @LastDateModified = '2014-05-25'
	
create table #Partitions(PartitionNum smallint not null);

-- Getting number of boundary values in partition function
select @BoundaryValuesCount = max(boundary_id) 
from sys.partition_functions pf join  
	sys.partition_range_values prf on
		pf.function_id = prf.function_id
where pf.name = 'pfData2'

;with Partitions(PartitionNum)
as
(
	select 1
	union all
	select PartitionNum + 1
	from Partitions
	where PartitionNum <= @BoundaryValuesCount
)
insert into #Partitions(PartitionNum)
	select PartitionNum from Partitions;

;with Steps1and2(Id, DateCreated, DateModified)
as 
(
	select top 100 PartData.ID, PartData.DateCreated, PartData.DateModified
	from #Partitions p
		cross apply
		(
			select top 100 Id, DateCreated, DateModified
			from dbo.Data
			where 
				DateModified > @LastDateModified and
				$Partition.pfData2(DateCreated) = 
					p.PartitionNum
			order by DateModified, ID
		) PartData
	order by PartData.DateModified, PartData.Id
)
-- Step 3 - CI seek as Key Lookup operation
select s.Id, s.DateCreated, s.DateModified, d.Placeholder
from Steps1and2 s join dbo.Data d on	
	d.Id = s.Id and s.DateCreated = d.DateCreated
order by s.DateModified, s.Id

drop table #Partitions
go

-- Hardcode Partition Numbers
declare 
	@LastDateModified datetime 

select @LastDateModified = '2014-05-25'

;with Partitions(PartitionNum)
as
(
	-- select v.V	from (values(1),(2),(3),(4),(5),(6),(7),(8)) v(V)
	select 1 union all select 2 union all select 3 union all select 4
	union all select 5 union all select 6 union all select 7 union all 
	select 8
)
,Steps1and2(Id, DateCreated, DateModified)
as 
(
	select top 100 PartData.ID, PartData.DateCreated, PartData.DateModified
	from Partitions p
		cross apply
		(
			select top 100 Id, DateCreated, DateModified
			from dbo.Data
			where 
				DateModified > @LastDateModified and
				$Partition.pfData2(DateCreated) = 
					p.PartitionNum
			order by DateModified, ID
		) PartData
	order by PartData.DateModified, PartData.Id
)
-- Step 3 - CI seek as Key Lookup operation
select s.Id, s.DateCreated, s.DateModified, d.Placeholder
from Steps1and2 s join dbo.Data d on	
	d.Id = s.Id and s.DateCreated = d.DateCreated
order by s.DateModified, s.Id
go
