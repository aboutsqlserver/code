/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 13: Utilizing In-Memory OLTP                     */
/*             03.Enforcing Referential Integrity Between                   */
/*         Disk-Based and Memory-Optimized Tables (Session 1)               */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop proc if exists dbo.InsertProductDescription;
drop table if exists dbo.ProductsInMem; 
drop table if exists dbo.ProductDescriptions;
go

create table dbo.ProductsInMem
(
    ProductId int not null
        constraint PK_ProductsInMem
        primary key nonclustered hash
        with (bucket_count = 65536),
    ProductName nvarchar(64) not null,

    index IDX_ProductsInMem_ProductName nonclustered(ProductName)
)
with (memory_optimized = on, durability = schema_and_data);

create table dbo.ProductDescriptions
(
    ProductId int not null,
    Description nvarchar(max) not null,
	
    constraint PK_ProductDescriptions
    primary key clustered(ProductId)
);
go

insert into dbo.ProductsInMem(ProductId, ProductName) 
values (1,N'Product 1');
go

create proc dbo.InsertProductDescription
(
	@ProductId int
	,@Description nvarchar(max)
)
as
begin
	set nocount on

	declare
		@Exists int

	set transaction isolation level read committed
	begin tran
		-- using REPEATABLE READ isolation level
		-- to build transaction read set
		select @Exists = ProductId  
		from dbo.ProductsInMem with (repeatableread)
		where ProductId = @ProductId;

		if @Exists is null
			raiserror('ProductId %d not found',16,1,@ProductId);
		else begin
			-- Emulating delay - run Session 2 during this time
			waitfor delay '00:00:15.000';

			insert into dbo.ProductDescriptions(ProductId, Description)
			values(1,@Description);
		end
	commit;
end
go

exec dbo.InsertProductDescription @ProductId = 1, @Description = N'Test';
go

-- Example of how to perform deletion of the ProductsInMem row
declare
	@Cnt int
	,@ProductId int = 1

begin tran
	-- using SERIALIZABLE isolation level to lock the key range
	select @Cnt = count(*)  
	from dbo.ProductDescriptions with (serializable)
	where ProductId = @ProductId;

	if @Cnt > 0
		raiserror('Referential Integrity Violation',16,1);
	else 
		delete from dbo.ProductsInMem with (snapshot)
		where ProductId = @ProductId;
commit;	
 