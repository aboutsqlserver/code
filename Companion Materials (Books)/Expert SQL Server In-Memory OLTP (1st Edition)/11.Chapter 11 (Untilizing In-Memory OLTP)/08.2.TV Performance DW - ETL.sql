/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*       08.Memory-Optimized Table Variable Performance (DW) - ETL          */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

/****************************************************************************/
/*       RECREATE TABLES AFTER EACH EXECUTION USING 08.1 SCRIPT!            */
/****************************************************************************/

/*** ETL Process ***/

declare 
	@DT datetime = getDate()
	,@Step1D int, @Step2D int, @Step3D int, @Step1M int, @Step2M int, @Step3M int

/* On Disk Table */

-- Step 1: Staging Table Insert
insert into dw.FactSalesETLDisk
    (OrderId,OrderNum,Product,ADate
        ,Quantity,UnitPrice,Amount)
        select OrderId,OrderNum,Product,ADate
            ,Quantity,UnitPrice,Amount
        from dbo.InputData;

/* Optional Index Creation */
--create index IDX1 on dw.FactSalesETLDisk(Product);

set @Step1D = datediff(millisecond,@DT,getDate()); set @DT = GetDate();

-- Step 2: DimProducts Insert
insert into dw.DimProducts(Product,ProductBin)
    select distinct f.Product, f.Product
    from dw.FactSalesETLDisk f
    where not exists
        (
            select * 
            from dw.DimProducts p
            where p.Product = f.Product
        );

set @Step2D = datediff(millisecond,@DT,getDate()); set @DT = GetDate();

-- Step 3: FactSales Insert
insert into dw.FactSales(ADateId,ProductId,OrderId,OrderNum,
    Quantity,UnitPrice,Amount)
        select d.ADateId,p.ProductId,f.OrderId,f.OrderNum,
            f.Quantity,f.UnitPrice,f.Amount
        from 
            dw.FactSalesETLDisk f join dw.DimDates d on
                f.ADate = d.ADate
            join dw.DimProducts p on 
                f.Product = p.Product;

set @Step3D = datediff(millisecond,@DT,getDate()); 

/* Memory-Optimized Table */
truncate table dw.FactSales;
waitfor delay '00:00:05.000';

set @DT = GetDate();
-- Step 1: Staging Table Insert
insert into dw.FactSalesETLMem
    (OrderId,OrderNum,Product,ADate
        ,Quantity,UnitPrice,Amount)
        select OrderId,OrderNum,Product,ADate
            ,Quantity,UnitPrice,Amount
        from dbo.InputData;
set @Step1M = datediff(millisecond,@DT,getDate()); set @DT = GetDate();

-- Step 2: DimProducts Insert
insert into dw.DimProducts(Product)
    select distinct f.Product
    from dw.FactSalesETLMem f
    where not exists
        (
            select * 
            from dw.DimProducts p
            where f.Product = p.ProductBin
        );
set @Step2M = datediff(millisecond,@DT,getDate()); set @DT = GetDate();

-- Step 3: FactSales Insert
insert into dw.FactSales(ADateId,ProductId,OrderId,OrderNum,
    Quantity,UnitPrice,Amount)
        select d.ADateId,p.ProductId,f.OrderId,f.OrderNum,
            f.Quantity,f.UnitPrice,f.Amount
        from 
            dw.FactSalesETLMem f join dw.DimDates d on
                f.ADate = d.ADate
            join dw.DimProducts p on 
                f.Product = p.ProductBin;
set @Step3M = datediff(millisecond,@DT,getDate()); 

select 
	'OnDisk' as [Table]
	,@Step1D as [Staging Table Insert]
	,@Step2D as [DimProducts Insert]
	,@Step3D as [FactSales Insert]
	,@Step1D + @Step2D + @Step3D as [Total Time]
union all
select
	'Memory-Optimized' as [Table]
	,@Step1M as [Staging Table Insert]
	,@Step2M as [DimProducts Insert]
	,@Step3M as [FactSales Insert]
	,@Step1M + @Step2M + @Step3M as [Total Time];
			
