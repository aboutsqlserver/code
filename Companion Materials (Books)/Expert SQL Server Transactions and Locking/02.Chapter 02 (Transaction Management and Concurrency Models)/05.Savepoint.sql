/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              02.Transaction Management and Concurrency Models            */
/*                         SET XACT_ABORT Behavior                          */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'TryDeleteCustomer') drop proc dbo.TryDeleteCustomer;
go

create proc dbo.TryDeleteCustomer
(
    @CustomerId int 
)
as
begin
    -- Setting XACT_ABORT to OFF for rollback to savepoint to work
    set xact_abort off

    declare
        @ActiveTran bit

    -- Check if SP is calling in context of active transaction
    set @ActiveTran = CASE WHEN @@TranCount > 0 THEN 1 ELSE 0 END;

    if @ActiveTran = 0
        begin tran;
    else 
        save transaction TryDeleteCustomer;

    begin try
        delete dbo.Customers where CustomerId = @CustomerId;

        if @ActiveTran = 0
            commit;
        return 0;
    end try
    begin catch
        if @ActiveTran = 0 or XACT_STATE() = -1
        begin
            -- Rollback entire transaction
            rollback tran; 
            return -1; 
        end
        else begin
                -- Rollback to savepoint 
            rollback tran TryDeleteCustomer; 
            return 1; 
        end
    end catch;
end;
go

declare
    @ReturnCode int

exec dbo.ResetData; 

begin tran
    exec @ReturnCode = TryDeleteCustomer @CustomerId = 1;
    select 
        1 as [CustomerId]
        ,@ReturnCode as [@ReturnCode]
        ,XACT_STATE() as [XACT_STATE()]
		,'','';
    
    if @ReturnCode >= 0
    begin
        exec @ReturnCode = TryDeleteCustomer @CustomerId = 2;
        select 
            2 as [CustomerId]
            ,@ReturnCode as [@ReturnCode]
            ,XACT_STATE() as [XACT_STATE()]
		,'','';
    end
if @ReturnCode >= 0
    commit;
else 
    if @@TRANCOUNT > 0
        rollback;
go

select * from dbo.Customers;
