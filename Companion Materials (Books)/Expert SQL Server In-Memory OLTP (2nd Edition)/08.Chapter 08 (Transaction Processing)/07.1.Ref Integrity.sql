/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*           Chapter 08: Transaction Processing in In-Memory OLTP           */
/*              07.Referential Integrity Enforcement (Session 1)            */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go


drop table if exists dbo.Transactions;
drop table if exists dbo.Branches;

create table dbo.Branches
(
	BranchId int not null 
		constraint PK_Branches
		primary key nonclustered hash with (bucket_count = 4)
)
with (memory_optimized = on, durability = schema_only);

create table dbo.Transactions
(
	TransactionId int not null 
		constraint PK_Transactions
		primary key nonclustered hash with (bucket_count = 4),
	BranchId int not null
		constraint FK_Transactions_Branches
		foreign key references dbo.Branches(BranchId),
	Amount money not null
)
with (memory_optimized = on, durability = schema_only);

insert into dbo.Branches(BranchId) values(1),(10);
insert into dbo.Transactions(TransactionId,BranchId,Amount)
values(1,1,10),(2,1,20);
go

-- Session 1 code
set transaction isolation level read committed
begin tran
	delete from dbo.Branches with (snapshot) where BranchId = 10;
	-- Run session 2 code
commit;


