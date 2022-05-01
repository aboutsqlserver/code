/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 03. Statistics                           */
/*                    Statistics and Execution Plans                        */
/****************************************************************************/

set noexec off
go

use [SqlServerInternals]
go

if not exists
(
	select * 
	from sys.tables t join sys.schemas s on 
		t.schema_id = s.schema_id 
	where s.name = 'dbo' and t.name = 'Books'
)
begin
	raiserror('Create dbo.Books table using "05.Nonclustered Index Usage.sql" script from 02.Chapter 02 project',16,1);
	set noexec on
end
go

/****************************************************************************/
/* IMPORTANT: This code behaves differently with new Cardinality Estimators */
/* in SQL Server 2014/2016                                                  */
/****************************************************************************/


-- Adding 250,000 rows = ~10% of table data. Statistics is not updated
;with Postfix(Postfix)
as
(
	select 100000001
	union all
	select Postfix + 1
	from Postfix
	where Postfix < 100250000
)
insert into dbo.Books(ISBN, Title)
	select 
		'999-0' + CONVERT(char(9),Postfix)
		,'Title for ISBN 999-0' + CONVERT(char(9),Postfix)
	from Postfix
option (maxrecursion 0);
go

-- Enable "Include Actual Execution Plan"
-- Check estimated # of rows vs. actual
set statistics io on
select * from dbo.Books where ISBN like '999%'; -- 250,000 rows
set statistics io off
go

dbcc show_statistics('dbo.Books',IDX_BOOKS_ISBN);
go

update statistics dbo.Books IDX_Books_ISBN with fullscan;
go

dbcc show_statistics('dbo.Books',IDX_BOOKS_ISBN);
go

set statistics io on
select * from dbo.Books where ISBN like '999%'; -- 250,000 rows
set statistics io off
go

