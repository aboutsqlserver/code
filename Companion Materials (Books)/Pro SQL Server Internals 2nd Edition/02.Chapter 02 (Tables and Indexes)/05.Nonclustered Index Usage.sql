/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*  Chapter 02. Tables and Indexes: Internal Structure and Access Methods   */
/*                      Nonclustered Index Usage                            */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Books') drop table dbo.Books;
go

create table dbo.Books
(
	BookId int identity(1,1) not null,
	Title nvarchar(256) not null,
	-- International Standard Book Number
	ISBN char(14) not null, 
	Placeholder char(150) null
);

create unique clustered index IDX_Books_BookId on dbo.Books(BookId);

-- 1,252,000 rows
;with Prefix(Prefix)
as
(
	select 100 
	union all
	select Prefix + 1
	from Prefix
	where Prefix < 600
)
,Postfix(Postfix)
as
(
	select 100000001
	union all
	select Postfix + 1
	from Postfix
	where Postfix < 100002500
)
insert into dbo.Books(ISBN, Title)
	select 
		CONVERT(char(3), Prefix) + '-0' + CONVERT(char(9),Postfix)
		,'Title for ISBN' + CONVERT(char(3), Prefix) + '-0' + CONVERT(char(9),Postfix)
	from Prefix cross join Postfix
option (maxrecursion 0);
go

create nonclustered index IDX_Books_ISBN on dbo.Books(ISBN);
go

-- Enable "Include Actual Execution Plan"
-- 2,500 rows
select * from dbo.Books where ISBN like '210%';
go

-- 12,500 rows
select * from dbo.Books where ISBN like '21[0-4]%';
select * from dbo.Books with (index = IDX_BOOKS_ISBN) where ISBN like '21[0-4]%';
go
