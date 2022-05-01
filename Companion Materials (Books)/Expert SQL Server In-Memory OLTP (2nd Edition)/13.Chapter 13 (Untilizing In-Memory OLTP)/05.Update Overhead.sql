/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 13: Utilizing In-Memory OLTP                     */
/*                         05.Update Overhead                               */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists dbo.MOTable;
drop table if exists dbo.DBTable;

create table dbo.MOTable
(
	Id int not null,
	IdxCol int not null,
	IntCol int not null,
	VarCharCol varchar(128) null,

	constraint PK_MOTable
	primary key nonclustered hash(Id)
	with (bucket_count = 2097152),

	index IdX_IdxCol nonclustered hash(IdxCol)
	with (bucket_count = 2097152),
)
with (memory_optimized=on, durability=schema_only)
go

create table dbo.DBTable
(
	Id int not null,
	IdxCol int not null,
	IntCol int not null,
	VarCharCol varchar(128) null,

	constraint PK_DBTable
	primary key clustered(Id)
);

create index IdX_DBTable_IdxCol on dbo.DBTable(IdxCol);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,N5(C) as (select 0 from N4 as t1 cross join N4 as t2) -- 65,536 rows
,N6(C) as (select 0 from N5 as t1 cross join N3 as t2) -- 1,048,576 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N6)
insert into dbo.MOTable(Id,IdxCol,IntCol)
	select Id, Id, Id from Ids;

insert into DBTable(Id, IdxCol, IntCol)
	select Id, IdxCol, IntCol from dbo.MOTable;
go

set statistics time on
update dbo.MOTable set IntCol += 1;
update dbo.MOTable set IdxCol += 1;
update dbo.MOTable set VarCharCol = replicate('a',128);

update dbo.DBTable set IntCol += 1;
update dbo.DBTable set IdxCol += 1;
update dbo.DBTable set VarCharCol = replicate('a',128);
set statistics time off
go

alter table dbo.MOTable
add index IdX_VarCharCol nonclustered(VarCharCol)
go

set statistics time on
update dbo.MOTable set IntCol += 1;
update dbo.MOTable set IdxCol += 1;
update dbo.MOTable set VarCharCol = replicate('b',128);
set statistics time off
go