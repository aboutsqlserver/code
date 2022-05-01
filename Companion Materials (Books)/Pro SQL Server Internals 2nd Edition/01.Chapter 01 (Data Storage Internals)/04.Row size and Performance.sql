/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 01. Data Storage Internals                     */
/*                       Row Size and Performance                           */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'SmallRows') drop table dbo.SmallRows;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'LargeRows') drop table dbo.LargeRows;
go

create table dbo.LargeRows
(
	ID int not null,
	Col char(2000) null
);

create table dbo.SmallRows
(
	ID int not null,
	Col varchar(2000) null
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.LargeRows(ID, Col) 
	select ID, 'Placeholder'
	from Ids;

insert into dbo.SmallRows(ID, Col) 
	select ID, 'Placeholder' 
	from dbo.LargeRows;
go

set statistics time, io on

select count(*) from dbo.LargeRows;
select count(*) from dbo.SmallRows;

set statistics time, io off
go

