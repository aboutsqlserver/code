/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 25. Query Optimization and Execution               */
/*                                Parallelism                               */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'T1') drop table dbo.T1;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'T2') drop table dbo.T2;
go

create table dbo.T1
(
	T1ID int not null,
	PlaceHolder char(100),
	constraint PK_T1
	primary key clustered(T1ID)
);

create table dbo.T2
(
	T1ID int not null,
	T2ID int not null,
	PlaceHolder char(100)
);

create unique clustered index IDX_T2_T1ID_T2ID
on dbo.T2(T1ID, T2ID);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,Nums(Num) as (select row_number() over (order by (select null)) from N5)
	insert into dbo.T1(T1ID)
		select Num from Nums;

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,Nums(Num) as (select row_number() over (order by (select null)) from N3)
	insert into dbo.T2(T1ID, T2ID)
		select T1ID, Num
		from dbo.T1 cross join Nums;
go


set statistics time on

select count(*)
from 
	(
		select t1.T1ID, count(*) as Cnt
		from dbo.T1 t1 join dbo.T2 t2 on 
			t1.T1ID = t2.T1ID
		group by t1.T1ID
	) s
option (maxdop 1);

select count(*)
from 
	(
		select t1.T1ID, count(*) as Cnt
		from dbo.T1 t1 join dbo.T2 t2 on 
			t1.T1ID = t2.T1ID
		group by t1.T1ID
	) s;

set statistics time off