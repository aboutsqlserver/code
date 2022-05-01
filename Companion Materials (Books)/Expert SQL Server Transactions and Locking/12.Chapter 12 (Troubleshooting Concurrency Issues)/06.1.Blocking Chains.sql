/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 12. Troubleshooting Concurrency Issues              */
/*                         Blocking Chain (Session 1)                       */
/****************************************************************************/

use SQLServerInternals
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'Delivery' and t.name = 'Customers') drop table Delivery.Customers;
go

create table Delivery.Customers 
(
	CustomerId int not null,
	Phone varchar(32) not null
);

insert into Delivery.Customers(CustomerId,Phone)
values(1,'111-111-1111'),(2,'222-222-2222');
go

begin tran
	update Delivery.Customers 
	set Phone = '111-111-1234'
	where CustomerId = 1; 


rollback