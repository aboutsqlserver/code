/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 22. Application Locks                       */
/*                 Workaround with Locking Hints (Session 2)                */
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
	raiserror('Please create [RawData] table with "01.Table Creation.sql" script',16,1) with nowait;
	set noexec on
end
go

-- Session 2 code
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
	output inserted.ID, inserted.Attributes ;
commit
go
