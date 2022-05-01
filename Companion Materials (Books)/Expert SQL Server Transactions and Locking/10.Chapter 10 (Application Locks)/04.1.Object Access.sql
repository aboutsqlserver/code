/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 10. Application Locks                       */
/*                  Preventing Access to the Object (Session 1)             */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go


if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'GetTenantData') drop proc dbo.GetTenantData;
go

create proc dbo.GetTenantData
(
	@TenantId int
	,@LastOnDate datetime
	,@PacketSize int
)
as
begin
	set nocount, xact_abort on

	declare
		@ResCode int
			
	begin tran
		exec @ResCode = sp_getapplock
			@Resource = 'TenantDataAccess'
			,@LockMode = 'Shared' 
			,@LockOwner = 'Transaction'
			,@LockTimeout = 0 ; -- No wait

		if @ResCode >= 0 -- success
		begin
			if @LastOnDate is null
				set @LastOnDate = '2018-01-01';
			
			select top (@PacketSize) with ties
				TenantId, OnDate, Id, Attributes
			from dbo.CollectedData
			where
				TenantId = @TenantId and 
				OnDate > @LastOnDate
			order by
				OnDate;
			
			waitfor delay '00:00:15.000'; -- Emulating delay
		end
		else
			-- return empty resultset
			select 
				convert(int,null) as TenantId
				,convert(datetime,null) as OnDate
				,convert(char(100),null) as Attributes
			where
				1 = 2;
	commit
end
go


-- Session 1 code
exec dbo.GetTenantData @TenantId = 1, @LastOnDate = null, @PacketSize = 50;
go
