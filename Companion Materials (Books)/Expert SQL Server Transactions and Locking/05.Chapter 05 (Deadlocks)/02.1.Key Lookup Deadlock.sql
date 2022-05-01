/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 05. Deadlocks				            */
/*                      Key Lookup Deadlock (Session 1)                     */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Data') drop table dbo.Data;
go

create table dbo.Data
(
	ClustKey int not null,
	Col1 int not null,
	NCIKey int not null,
	IncludedCol int not null,
	Placeholder char(8000),
)
go

create unique clustered index IDX_CI
on dbo.Data(ClustKey)
go

create unique nonclustered index IDX_NCI
on dbo.Data(NCIKey)
include(IncludedCol)
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N4)
insert into dbo.Data(ClustKey, Col1, NCIKey, IncludedCol) 
	select ID, ID, ID, ID
	from IDs;
go


/*** TEST ***/
-- Session 1 code (Run in parallel with Session 2 code)
declare
	@I int 

select @I = 1

while 1 = 1
begin
	update dbo.Data
	set IncludedCol = @I
	where ClustKey = 10;
	
	select @I = @I + 1;
end
go
/*** TEST ENDS ***/

-- Checking the locks
begin tran
	update dbo.Data
	set Col1 = 0
	where ClustKey = 1;
	
	select 
		l.request_session_id as [SPID]
		,object_name(p.object_id) as [Object]
		,i.name as [Index]
		,l.resource_type as [Lock Type]
		,l.resource_description as [Resource]
		,l.request_mode as [Mode]
		,l.request_status as [Status]
		,wt.blocking_session_id as [Blocked By]
	from 
		sys.dm_tran_locks l join sys.partitions p on
			p.hobt_id = l.resource_associated_entity_id
		join sys.indexes i on 
			p.object_id = i.object_id and 
			p.index_id = i.index_id	
		left outer join sys.dm_os_waiting_tasks wt on
			l.lock_owner_address = wt.resource_address and 
			l.request_status = 'WAIT'
	where 
		resource_type = 'KEY' and 
		request_session_id = @@SPID; 
commit
go

begin tran
	update dbo.Data
	set IncludedCol = 0
	where ClustKey = 1
	
	select 
		l.request_session_id as [SPID]
		,object_name(p.object_id) as [Object]
		,i.name as [Index]
		,l.resource_type as [Lock Type]
		,l.resource_description as [Resource]
		,l.request_mode as [Mode]
		,l.request_status as [Status]
		,wt.blocking_session_id as [Blocked By]
	from 
		sys.dm_tran_locks l join sys.partitions p on
			p.hobt_id = l.resource_associated_entity_id
		join sys.indexes i on 
			p.object_id = i.object_id and 
			p.index_id = i.index_id	
		left outer join sys.dm_os_waiting_tasks wt on
			l.lock_owner_address = wt.resource_address and 
			l.request_status = 'WAIT'
	where 
		resource_type = 'KEY' and 
		request_session_id = @@SPID;
commit
go
