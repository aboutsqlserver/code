/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 10. Application Locks                       */
/*                      Application Locks (Session 1)                       */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'LoadRawData') drop proc dbo.LoadRawData;
go

create proc dbo.LoadRawData(@PacketSize int)
as
begin
	set nocount on
	set xact_abort on
	
	declare
		@EarliestProcessingTime datetime
		,@ResCode int
		
	declare
		@Data table
		(
			ID int not null,
			Attributes char(100) not null,
			primary key(ID)
		)
		
	begin tran
		exec @ResCode = sp_getapplock
			@Resource = 'LoadRowDataLock'
			,@LockMode = 'Exclusive' 
			,@LockOwner = 'Transaction'
			,@LockTimeout = 15000 ;-- 15 seconds

		if @ResCode >= 0 -- success
		begin
			-- We're assuming that app server would process the packet 
			-- within 1 minute unless crashed
			select @EarliestProcessingTime = dateadd(minute,-1,getutcdate());
				
			;with DataPacket(ID, Attributes, ProcessingTime)
			as
			(
				select top (@PacketSize)	
					ID, Attributes, ProcessingTime
				from dbo.RawData
				where ProcessingTime <= @EarliestProcessingTime
				order by ID
			)
			update DataPacket
			set ProcessingTime = getutcdate()
			output inserted.ID, inserted.Attributes 
			into @Data(ID, Attributes);
		end
		-- Adding delay to emulate concurrent access
		waitfor delay '00:00:10.000';
		
		-- we don't need to explicitly release application lock
		-- because @LockOwner is Transaction
	commit
	
	select ID, Attributes from @Data;
end
go


-- Session 1 code
exec dbo.LoadRawData @PacketSize = 50;
-- Run session 2 code immediately
go
