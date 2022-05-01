/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 03. Statistics                           */
/*                          Exploring Statistics                            */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/*** IMPORTANT: Script uses dbo.Books table created in Chapter 02 scripts ***/
/****************************************************************************/

;with Prefix(Prefix)
as
(
	-- select Num from (values(104),(104),(104),(104),(104)) Num(Num)
	select 104 union all select 104 union all select 104 union all select 104 union all select 104
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

-- Updating the statistics
update statistics dbo.Books IDX_Books_ISBN with fullscan;
go

dbcc show_statistics('dbo.Books',IDX_BOOKS_ISBN) 
go

-- The code below requires SQL Server 2008R2 SP2/SQL Server 2012 SP1 to execute
select
	s.stats_id as [Stat ID]
	,sc.name + '.' + t.name as [Table]
	,s.name as [Statistics]
	,p.last_updated
	,p.rows
	,p.rows_sampled
	,p.modification_counter as [Mod Count]
from
	sys.stats s join sys.tables t on 
		s.object_id = t.object_id
	join sys.schemas sc on
		t.schema_id = sc.schema_id
	outer apply
		sys.dm_db_stats_properties(t.object_id,s.stats_id) p
where	
	sc.name = 'dbo' and t.name = 'Books'
