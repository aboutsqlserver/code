/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                      Chapter 22. Application Locks                       */
/*                 Workaround with Locking Hints (Session 1)                */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

if not exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'RawData'    
)
begin
	raiserror('Please create [RawData] table with "01.Table Creation.sql" script',16,1) with nowait
	set noexec on
end
go

-- Session 1 code
-- Using transaction and waitfor delay to emulate concurrent activity

-- STEP 1
declare
	@EarliestProcessingTime datetime 
select @EarliestProcessingTime = dateadd(minute,-1,getutcdate())

begin tran
	;with DataPacket(ID, Attributes, ProcessingTime)
	as
	(
		select top (50)	ID, Attributes, ProcessingTime
		from dbo.RawData with (updlock, readpast)
		where ProcessingTime <= @EarliestProcessingTime
		order by ID
	)
	update DataPacket
	set ProcessingTime = getutcdate()
	output inserted.ID, inserted.Attributes 

	-- Run Session 2 code. All Exclusive locks are held now
commit
go
