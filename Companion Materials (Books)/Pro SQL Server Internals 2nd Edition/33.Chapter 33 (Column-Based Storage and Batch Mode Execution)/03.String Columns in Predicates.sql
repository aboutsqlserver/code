/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*          Chapter 33. Column-Based Storage and Batch Mode Execution       */
/*                        Columnstore Index Metadata                        */
/****************************************************************************/

set noexec off
go

set nocount on
go

/****************************************************************************/
/* This script takes several minutes to execute and will generate large     */
/* (several GBs) data and log files                                         */
/****************************************************************************/

use [SqlServerInternals]
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 11 
begin
	raiserror('You should have SQL Server 2012+ to execute this script',16,1) with nowait;
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

if not exists
(
	select * 
	from sys.tables t join sys.schemas s on 
		t.schema_id = s.schema_id 
	where s.name = 'dbo' and t.name = 'FactSales'
)
begin
	raiserror('Create dbo.FactSales table with "01.Batch Mode Execution.sql" script',16,1);
	set noexec on
end
go

if not exists
(
	select * 
	from 
		sys.tables t join sys.schemas s on 
			t.schema_id = s.schema_id 
		join sys.columns c on 
			t.object_id = c.object_id 
	where s.name = 'dbo' and t.name = 'FactSales' and c.name = 'ArticleCategory'
)
begin
	drop index IDX_FactSales_ColumnStore on dbo.FactSales;
	
	alter table dbo.FactSales add ArticleCategory nvarchar(32) not null default '';

	exec sp_executesql N'
update t
set
	t.ArticleCategory = a.ArticleCategory
from 
	dbo.FactSales t join dbo.DimArticles a on
		t.ArticleId = a.ArticleId;';

	exec sp_executesql N'
create nonclustered columnstore index IDX_FactSales_ColumnStore
on dbo.FactSales(DateId, ArticleId, BranchId, Quantity, UnitPrice, Amount, ArticleCategory);';
end
go

-- Enable "Include Actual Execution Plan"

-- You will get different execution plans in different versions of SQL Server. 
-- In SQL Server 2016, String predicate may be pushed to CCI Scan operator 
set statistics time, io on

select sum(s.Amount) as [Sales]
from 
	dbo.FactSales s join dbo.DimBranches b on
		s.BranchId = b.BranchId
	join dbo.DimArticles a on
		s.ArticleId = a.ArticleId	
where
	b.BranchNumber = N'3' and 
	a.ArticleCategory = N'Category 4';

select sum(s.Amount) as [Sales]
from 
	dbo.FactSales s join dbo.DimBranches b on
		s.BranchId = b.BranchId
where
	b.BranchNumber = N'3' and 
	s.ArticleCategory = N'Category 4';

set statistics time, io off
go

