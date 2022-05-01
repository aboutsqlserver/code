/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 25. Query Optimization and Execution               */
/*                 Variable-Length Columns and Memory Grants                */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Data1') drop table dbo.Data1;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Data2') drop table dbo.Data2;
go

create table dbo.Data1
(
	ID int not null,
	Value varchar(100) not null,
	constraint PK_Data1
	primary key clustered(ID)
);

create table dbo.Data2
(
	ID int not null,
	Value varchar(200) not null,
	constraint PK_Data2
	primary key clustered(ID)
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2 ) -- 65,536 rows
,Nums(Num) as (select row_number() over (order by (select null)) from N5)
	insert into dbo.Data1(ID, Value)
		select Num , replicate('0',100)
		from Nums;

insert into dbo.Data2(ID, Value)
	select ID, Value from dbo.Data1;
go

-- Enable "Include Actual Execution Plan"
-- Monitor "Sort Warnings" 
-- In SQL Server prior 2012 you would not see it in the execution plan
-- You can use Profiler monitoring SORT WARNING event instead
-- Different versions of SQL Server/SP may require you to adjust the # of rows
-- For example SQL Server 2016 RTM in my environment requies to use 40450 to demonstrate
-- this behavior
declare
	@V varchar(200)

select @V = Value
from dbo.Data1
where ID < 40450
order by Value, ID desc;

select @V = Value
from dbo.Data2
where ID < 40450
order by Value, ID desc;
