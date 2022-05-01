/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 23. Schema Locks				            */
/*                    Low Priority Locks (Session 1)                        */
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
	) < 12 
begin
	raiserror('You should have SQL Server 2014-2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Data') drop table dbo.Data;
go

create table dbo.Data
(
	ID int  not null,
	Col char(2000),

	constraint PK_Data
	primary key clustered(ID)
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N4)
insert into dbo.Data(ID) 
	select ID
	from IDs;
go

-- STEP 1: 
begin tran
	select *
	from dbo.Data with (repeatableread)
	where Id = 1;
		  
	-- Run Session 2 

	select
		TL1.resource_type as [Resource Type]
		,db_name(TL1.resource_database_id) as [DB Name]
		,case TL1.resource_type
			when 'OBJECT' then 
				object_name(TL1.resource_associated_entity_id
					,TL1.resource_database_id)
			when 'DATABASE' then
				'DB'
			else
				case
					when TL1.resource_database_id = db_id() 
					then
					(
						select object_name(object_id
								,TL1.resource_database_id)
						from sys.partitions
						where hobt_id =
							TL1.resource_associated_entity_id
					)
					else
						'(Run under DB context)'
				end
		end as [Object]
		,TL1.resource_description as [Resource]
		,TL1.request_session_id as [Session]
		,TL1.request_mode as [Mode]
		,TL1.request_status as [Status]
		,WT.wait_duration_ms as [Wait (ms)]
		,QueryInfo.sql
	from
		sys.dm_tran_locks TL1 with (nolock) 
			join sys.dm_tran_locks TL2 with (nolock) on
				TL1.resource_associated_entity_id =
					TL2.resource_associated_entity_id
			left outer join sys.dm_os_waiting_tasks WT with (nolock) on
				TL1.lock_owner_address = WT.resource_address and 
				TL1.request_status = 'WAIT'
		outer apply
		(
			select
				substring(
					S.Text, 
					(ER.statement_start_offset / 2) + 1,
					((
						case 
							ER.statement_end_offset
						when -1 
							then datalength(S.text)
							else ER.statement_end_offset
						end - ER.statement_start_offset) / 2) + 1
				) as sql
			from 
				sys.dm_exec_requests ER with (nolock)
					cross apply sys.dm_exec_sql_text(ER.sql_handle) S
			where
				TL1.request_session_id = ER.session_id
		)  QueryInfo
	where
		TL1.request_status <> TL2.request_status and
		(
			TL1.resource_description = TL2.resource_description OR
			(TL1.resource_description is null and 
				TL2.resource_description is null)
		)
	option (recompile);

rollback
go