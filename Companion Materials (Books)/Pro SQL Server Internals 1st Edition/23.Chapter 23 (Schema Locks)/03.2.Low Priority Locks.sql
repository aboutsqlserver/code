/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                       Chapter 23. Schema Locks				            */
/*                    Low Priority Locks (Session 2)                        */
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
	raiserror('You should have SQL Server 2014 to execute this script',16,1) with nowait
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/

-- TEST 1: Regular locks
-- Session is blocked blocking other sessions from accessing the data 
alter index PK_Data on dbo.Data rebuild
with (online = on)
-- RUN Session 3 code now - it would be blocked
go


-- TEST 2: Low Priority locks
-- Even though session is blocked, it does not block other sessions
alter index PK_Data on dbo.Data rebuild
with 
(
	online = on
	(
		wait_at_low_priority
		(
			max_duration=1 minutes, 
			abort_after_wait=blockers
		)

	)
)
-- RUN Session 3 code now - it would NOT be blocked
go

