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

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'GenerateError') drop proc dbo.GenerateError;
go

create proc dbo.GenerateError
as
begin
    set xact_abort on
    begin tran
        delete from dbo.Customers where CustomerId = 2; -- Error
        select 'This statement will never be executed';
end
go


exec dbo.GenerateError;
select 'This statement will never be executed';
go

select XACT_STATE() as [XACT_STATE()], @@TRANCOUNT as [@@TRANCOUNT];
go

-- Test 2: TRY..CATCH block
begin try
	exec dbo.GenerateError;
	select 'This statement will never be executed';
end try
begin catch
	select 
		ERROR_NUMBER() as [Error Number]
		,ERROR_PROCEDURE() as [Procedure]
		,ERROR_LINE() as [Error Line]
		,ERROR_MESSAGE() as [Error Message];

	select 
		XACT_STATE() as [XACT_STATE()]
		,@@TRANCOUNT as [@@TRANCOUNT];

	if @@TRANCOUNT > 0
		rollback;
end catch
go

