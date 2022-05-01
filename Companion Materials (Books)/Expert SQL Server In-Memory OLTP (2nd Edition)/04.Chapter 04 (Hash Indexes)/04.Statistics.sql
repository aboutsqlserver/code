/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 04: Hash Indexes                           */
/*                            04.Statistics                                 */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists dbo.Stats120;
drop table if exists dbo.Stats130;
go

alter database current set compatibility_level=120;
go

create table dbo.Stats120
(
	Id int not null
		constraint PK_Stats120
		primary key nonclustered 
		hash with (bucket_count=1024),
	Value int not null
) 
with (memory_optimized=on, durability=schema_only);
go

alter database current set compatibility_level=130;
go

create table dbo.Stats130
(
	Id int not null
		constraint PK_Stats130
		primary key nonclustered 
		hash with (bucket_count=1024),
	Value int not null
) 
with (memory_optimized=on, durability=schema_only);
go

select
	sc.name + '.' + t.name as [Table]
	,s.name as [Statistics]
	,s.no_recompute 
from 
	sys.stats s join sys.tables t on 
		s.object_id = t.object_id
	join sys.schemas sc on
		t.schema_id = sc.schema_id
where
	t.name like 'Stats%';
go

declare
	@SQL nvarchar(max)

select 
	@SQL = convert(nvarchar(max), 
	(
		select 
			N'update statistics ' as [text()]
			,sc.name + N'.' + t.name as [text()]
			,N'(' + s.name + N'); ' as [text()]
		from 
			sys.stats s join sys.tables t on 
				s.object_id = t.object_id
			join sys.schemas sc on
				t.schema_id = sc.schema_id
		where
			t.is_memory_optimized = 1 and 
			s.no_recompute = 1
		for xml path('')
	));

exec sp_executesql @SQL;
go

select
	sc.name + '.' + t.name as [Table]
	,s.name as [Statistics]
	,s.no_recompute 
from 
	sys.stats s join sys.tables t on 
		s.object_id = t.object_id
	join sys.schemas sc on
		t.schema_id = sc.schema_id
where
	t.name like 'Stats%';
go
