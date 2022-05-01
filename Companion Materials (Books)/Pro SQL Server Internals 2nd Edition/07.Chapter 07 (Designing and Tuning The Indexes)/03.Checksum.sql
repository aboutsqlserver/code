/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 07. Designing and Tuning The Indexes               */
/*                               CHECKSUM()                                 */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Articles') drop table dbo.Articles;
go

create table dbo.Articles
(
	ArticleId int not null,
	ExternalId uniqueidentifier not null	
		constraint DEF_Articles_ExternalId
		default newid(),
	ExternalIdCheckSum as checksum(ExternalId),
	/* Other Columns */
);

create unique clustered index IDX_Articles_ArticleId 
on dbo.Articles(ArticleId);

create nonclustered index IDX_Articles_ExternalIdCheckSum
on dbo.Articles(ExternalIdCheckSum);
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.Articles(ArticleId)
	select ID from IDs
go

-- Enable "Include Actual Execution Plan"

declare
	@ExternalId uniqueidentifier
  
select @ExternalId = ExternalId from dbo.Articles where ArticleId = 42;

select *
from dbo.Articles
where checksum(@ExternalId) = ExternalIdCheckSum and ExternalId = @ExternalId;
go