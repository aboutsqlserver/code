/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 03. Statistics                           */
/*                    Statistics and Execution Plans                        */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/*** IMPORTANT: Scripts use dbo.Books table created in Chapter 02 scripts ***/
/****************************************************************************/

/****************************************************************************/
/*** IMPORTANT: This code behaves differently with new SQL Server 2014 CE ***/
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
option (maxrecursion 0)
go

-- Enable "Include Actual Execution Plan"
-- Check estimated # of rows vs. actual
set statistics io on
select * from dbo.Books where ISBN like '999%' -- 250,000 rows
set statistics io off
go


dbcc show_statistics('dbo.Books',IDX_BOOKS_ISBN) 
go

update statistics dbo.Books IDX_Books_ISBN with fullscan;
go

dbcc show_statistics('dbo.Books',IDX_BOOKS_ISBN) 
go

set statistics io on
select * from dbo.Books where ISBN like '999%' -- 250,000 rows
set statistics io off
go

