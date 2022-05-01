/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                 Chapter 33. In-Memory OLTP Programmability               */
/*                          Execution Statistics 		                    */
/****************************************************************************/

set noexec off
go

set nocount on
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

if convert(int, serverproperty('EngineEdition')) != 3 or charindex('X64',@@Version) = 0
begin
	raiserror('That script requires 64-Bit Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

if not exists (select * from sys.databases where name = 'SQLServerInternalsHK')
begin
	raiserror('Create [SQLServerInternalsHK] database with "03.Create Hekaton DB.sql" script from "00.Init" project',16,1)
	set noexec on
end
go

use SQLServerInternalsHK
go

if exists(
	select * 
	from sys.procedures p join sys.schemas s on 
		p.schema_id = s.schema_id
	where 
		p.name = 'ExecStatProc' and s.name = 'dbo' 
)
	drop proc dbo.ExecStatProc
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on 
		t.schema_id = s.schema_id 
	where s.name = 'dbo' and t.name = 'ExecStatData'
)
	drop table dbo.ExecStatData
go

create table dbo.ExecStatData
(
	ID int not null
		primary key nonclustered
		hash with (bucket_count=1000),
	Value int null
)
with (memory_optimized=on, durability=schema_only);
go

create proc dbo.ExecStatProc
with native_compilation, schemabinding, execute as owner
as
begin atomic
with (transaction isolation level = snapshot, language=N'us_english')
	declare
		@I int = 0
	while @I < 1000
	begin
		insert into dbo.ExecStatData(ID, Value)
		values(@I, @I);

		select @I += 1
	end

	delete from dbo.ExecStatData
end
go

/*** Enable Execution Statistics Collection ***/
exec sys.sp_xtp_control_proc_exec_stats 1
exec sys.sp_xtp_control_query_exec_stats 1
go

/*** You can clear plan cache with DBCC FREEPROCCACHE command. Do not run in production ***/

/*** Calling SP ***/
exec dbo.ExecStatProc
go



/*** Stored Procedure Execution Statistics ***/
select 
	object_name(object_id) as [Proc Name]
	,execution_count as [Exec Cnt]
	,total_worker_time as [Total CPU]
	,case 
		when execution_count = 0
		then 0
		else convert(int,total_worker_time / 1000 / execution_count) 
	end	as [Avg CPU] -- in Milliseconds
	,total_elapsed_time as [Total Elps]
	,case 
		when execution_count = 0
		then 0
		else convert(int,total_elapsed_time / 1000 / execution_count) 
	end as [Avg Elps] -- in Milliseconds 
	,cached_time as [Cached]
	,last_execution_time as [Last Exec]  
	,sql_handle
	,plan_handle
	,total_logical_reads as [Reads]
	,total_logical_writes as [Writes]
from 
	sys.dm_exec_procedure_stats
order by 
	[AVG CPU] desc
go


/*** Statements Execution Statistics ***/
select 
	substring(qt.text, (qs.statement_start_offset/2)+1,
		((
			case qs.statement_end_offset
				when -1 then datalength(qt.text)
				else qs.statement_end_offset
			end - qs.statement_start_offset)/2)+1) as SQL
	,qs.execution_count as [Exec Cnt]
	,qs.total_worker_time as [Total CPU]
	,convert(int,qs.total_worker_time / 1000 / qs.execution_count) 
		as [Avg CPU] -- in Milliseconds
	,total_elapsed_time as [Total Elps]
	,convert(int,qs.total_elapsed_time / 1000 / qs.execution_count) 
		as [Avg Elps] -- in Milliseconds
	,qs.creation_time as [Cached]
	,last_execution_time as [Last Exec]  
	,qs.plan_handle
	,qs.total_logical_reads as [Reads]
	,qs.total_logical_writes as [Writes]
from 
	sys.dm_exec_query_stats qs
		cross apply sys.dm_exec_sql_text(qs.sql_handle) qt
where 
	qs.plan_generation_num is null
order by 
	[AVG CPU] desc
go