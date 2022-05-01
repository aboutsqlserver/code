/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*  Chapter 02. Tables and Indexes: Internal Structure and Access Methods   */
/*                         Heap Tables and PFS                              */
/****************************************************************************/

use [SqlServerInternals]
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Heap'    
)
	drop table dbo.Heap
go

create table dbo.Heap
(
	Val varchar(8000) not null
);

;with CTE(ID,Val)
as
(
	select 1, replicate('0',4089)
	union all
	select ID + 1, Val from CTE where ID < 20
)
insert into dbo.Heap
	select Val from CTE;
go

select page_count, avg_record_size_in_bytes, avg_page_space_used_in_percent
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.Heap'),0,null,'DETAILED');

insert into dbo.Heap(Val) values(replicate('1',100));

select page_count, avg_record_size_in_bytes, avg_page_space_used_in_percent
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.Heap'),0,null,'DETAILED');

insert into dbo.Heap(Val) values(replicate('2',2000));

select page_count, avg_record_size_in_bytes, avg_page_space_used_in_percent
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.Heap'),0,null,'DETAILED');
