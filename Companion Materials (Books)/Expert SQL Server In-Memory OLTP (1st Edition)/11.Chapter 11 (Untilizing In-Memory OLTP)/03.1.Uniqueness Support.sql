/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*                  03.Enforcing Uniqueness (Session 1)                     */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go


if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'InsertProduct') drop proc dbo.InsertProduct; 
go

if not exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'ProductsInMem')
begin
	raiserror('Please create dbo.ProductsInMem table using "01.Vertical Partitioning.sql" script',16,1)
	set noexec on
end
go

create procedure dbo.InsertProduct
(
    @ProductName nvarchar(64) not null
    ,@ShortDescription nvarchar(256) not null
    ,@ProductId int output
)
with native_compilation, schemabinding, execute as owner
as
begin atomic with
(
    transaction isolation level = serializable
    ,language = N'English'
)
    declare
        @Exists bit = 0

    -- Building scan set and checking
    -- existense of the product
    select @Exists = 1
    from dbo.ProductsInMem
    where ProductName = @ProductName

    if @Exists = 1
    begin
	;throw 50000, 'Product Already Exists', 1;
	return
    end

    insert into dbo.ProductsInMem(ProductName, ShortDescription)
    values(@ProductName, @ShortDescription);

    select @ProductID = scope_identity()
end
go

-- Session 1 code
declare
	@ProductId int

-- Running in transaction to simulate concurrent execution
begin tran
	exec dbo.InsertProduct
		'Expert SQL Server In-Memory OLTP'
		,'Published by APress'
		,@ProductId output;

	-- Run Session 2 code
commit


