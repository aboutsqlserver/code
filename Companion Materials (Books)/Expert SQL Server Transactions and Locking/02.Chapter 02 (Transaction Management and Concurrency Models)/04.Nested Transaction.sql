/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              02.Transaction Management and Concurrency Models            */
/*                           Nested Transactions                            */
/****************************************************************************/

set nocount on
go

select @@TRANCOUNT as [Original @@TRANCOUNT];
begin tran
    select @@TRANCOUNT as [@@TRANCOUNT after the first BEGIN TRAN];
    begin tran
        select @@TRANCOUNT as [@@TRANCOUNT after the second BEGIN TRAN];
    commit
    select @@TRANCOUNT as [@@TRANCOUNT after nested COMMIT];    
    begin tran
        select @@TRANCOUNT as [@@TRANCOUNT after the third BEGIN TRAN];
    rollback
select @@TRANCOUNT as [@@TRANCOUNT after ROLLBACK];
rollback; -- This ROLLBACK generates the error
