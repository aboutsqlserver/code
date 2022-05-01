/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 13: Utilizing In-Memory OLTP                     */
/*                04.Implementing Optimistic Concurrency                    */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists dbo.OptimisticConcurrency;
go

create table dbo.OptimisticConcurrency
(
	ID int not null
	    constraint PK_OptimisticConcurrency
        primary key nonclustered,
	Data int not null, 
	RowVer uniqueidentifier not null
		constraint DEF_OptimisticConcurrency_RowVer
		default newid()
)
with (memory_optimized = on, durability = schema_only)
go

insert into dbo.OptimisticConcurrency(ID, Data) 
values(1,1);

-- Reading data from the client
declare
	@ID int = 1
	,@NewData int = 2

declare
	@Data int
	,@OldRowVer uniqueidentifier

select @Data = Data, @OldRowVer = RowVer
from dbo.OptimisticConcurrency
where ID = @ID;

-- Saving data to the database
update dbo.OptimisticConcurrency
set 
	Data = @NewData
	,RowVer = newid()
where ID = @ID and RowVer = @OldRowVer;

if @@rowcount = 0
	raiserror('Row with ID: %d has been modified by other session',
		16,1,@ID);
