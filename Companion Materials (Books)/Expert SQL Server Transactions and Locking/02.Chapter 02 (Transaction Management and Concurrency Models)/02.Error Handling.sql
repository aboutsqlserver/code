/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              02.Transaction Management and Concurrency Models            */
/*                              Error Handling                              */
/****************************************************************************/

set nocount on
set xact_abort off
go

use SQLServerInternals
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'ResetData') drop proc dbo.ResetData;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Orders') drop table dbo.Orders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Customers') drop table dbo.Customers;
go

create table dbo.Customers
(
    CustomerId int not null,
	constraint PK_Customers
	primary key(CustomerId)
);

create table dbo.Orders
(
    OrderId int not null,
    CustomerId int not null,

    constraint FK_Orders_Customerss
    foreign key(CustomerId)
    references dbo.Customers(CustomerId)
);
go

create proc dbo.ResetData
as
begin
    begin tran
        delete from dbo.Orders;
        delete from dbo.Customers;
        insert into dbo.Customers(CustomerId) values(1),(2),(3);
        insert into dbo.Orders(OrderId, CustomerId) values(2,2);
    commit
end;
go

exec dbo.ResetData;
go

select * from dbo.Customers;
select * from dbo.Orders;
go

-- Test 1: Running three deletions in the batch

delete from  dbo.Customers where CustomerId = 1; -- Success
select @@ERROR as [@@ERROR: CustomerId = 1];
delete from  dbo.Customers where CustomerId = 2; -- FK Violation
select @@ERROR as [@@ERROR: CustomerId = 2];
delete from  dbo.Customers where CustomerId = 3; -- Success
select @@ERROR as [@@ERROR: CustomerId = 3];
go

select * from dbo.Customers;
go

-- Test 2: Try..Catch
exec dbo.ResetData;
go

begin try
    delete from  dbo.Customers where CustomerId = 1; -- Success
    delete from  dbo.Customers where CustomerId = 2; -- FK Violation
    delete from  dbo.Customers where CustomerId = 3; -- Not executed
end try
begin catch
    select 
        ERROR_NUMBER() as [Error Number]
        ,ERROR_LINE() as [Error Line]
        ,ERROR_MESSAGE() as [Error Message];
end catch
go

select * from dbo.Customers;
go

