/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 27. Extended Events                        */
/*                          Creating Event Session                          */
/****************************************************************************/

set noexec off
go


if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 11 -- SQL Server 2012/2014 is required
begin
	raiserror('You should have SQL Server 2012+ to execute this script',16,1) with nowait;
	raiserror('SQL Server 2008/2008R2 does not support hash_warning/sort_warning events',16,1) with nowait;
	set noexec on
end
go

if exists(select * from sys.server_event_sessions where name = 'TempDB Spills') drop event session [TempDB Spills] on server;
go

create event session [TempDB Spills] 
on server
add event
	sqlserver.hash_warning
	(
		action
		(
			sqlserver.session_id
			,sqlserver.plan_handle
			,sqlserver.sql_text
		)
		where(sqlserver.is_system=0)
	), 
add event
	sqlserver.sort_warning
	(
		action
		(
			sqlserver.session_id
			,sqlserver.plan_handle
			,sqlserver.sql_text
		)
		where(sqlserver.is_system=0)
	)
add target
	 package0.event_file
	 (set filename='c:\ExtEvents\TempDB_Spiils.xel',max_file_size=25),
add target 
	package0.ring_buffer
	(set max_memory=4096)
with	
(
	max_memory=4096KB
	,event_retention_mode=allow_single_event_loss
	,max_dispatch_latency=15 seconds
	,track_causality=off
	,memory_partition_mode=none
	,startup_state=off
);
go

alter event session [TempDB Spills]
on server
state=start;
go

-- Clean-Up - This session is used in the other demos/scripts from the chapter
/*
alter event session [TempDB Spills]
on server
state=stop;
go

drop event session [TempDB Spills] on server;
go
*/