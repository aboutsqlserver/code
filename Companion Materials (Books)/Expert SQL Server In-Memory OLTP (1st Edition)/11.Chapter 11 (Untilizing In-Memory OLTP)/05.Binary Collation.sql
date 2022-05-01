/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*                    05.Binary Collation Performance                       */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'CollationTest') drop table dbo.CollationTest; 
if object_id(N'tempdb..#CollData') is not null drop table #CollData;
go

create table dbo.CollationTest
(
    ID int not null,
    VarCol varchar(108) not null,
    NVarCol nvarchar(108)  not null,
    VarColBin varchar(108) 
		collate Latin1_General_100_BIN2 not null,
    NVarColBin nvarchar(108) 
		collate Latin1_General_100_BIN2 not null,
    
    constraint PK_CollationTest
    primary key nonclustered hash(ID)
	with (bucket_count=131072),

)
with (memory_optimized=on, durability=schema_only)
go

create table #CollData
(
    ID int not null,
    Col1 uniqueidentifier not null
        default NEWID(),
    Col2 uniqueidentifier not null
        default NEWID(),
    Col3 uniqueidentifier not null
        default NEWID()
)
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into #CollData(ID)
    select ID from IDs;

insert into dbo.CollationTest(ID,VarCol,NVarCol,VarColBin,NVarColBin)
	select
		ID,
        /* VarCol */
		convert(varchar(36),Col1) + 
		convert(varchar(36),Col2) +
        convert(varchar(36),Col3),
        /* NVarCol */ 
		convert(nvarchar(36),Col1) +
        convert(nvarchar(36),Col2) +
        convert(nvarchar(36),Col3),
        /* VarColBin */
		convert(varchar(36),Col1) + 
		convert(varchar(36),Col2) +
        convert(varchar(36),Col3),
        /* NVarColBin */ 
		convert(nvarchar(36),Col1) +
        convert(nvarchar(36),Col2) +
        convert(nvarchar(36),Col3)
	from 
		#CollData
go

declare
	@Param varchar(16) 
	,@NParam varchar(16) 

select 
	@Param = substring(VarCol,43,6)
	,@NParam = substring(NVarCol,43,6)
from
	dbo.CollationTest
where
	ID = 1000;

set statistics time on

select count(*)
from dbo.CollationTest
where VarCol like '%' + @Param + '%';

select count(*)
from dbo.CollationTest
where NVarCol like '%' + @NParam + N'%';

select count(*)
from dbo.CollationTest
where VarColBin like '%' + upper(@Param) + '%' collate Latin1_General_100_Bin2;

select count(*)
from dbo.CollationTest
where NVarColBin like '%' + upper(@NParam) + N'%' collate Latin1_General_100_Bin2;

set statistics time off
go