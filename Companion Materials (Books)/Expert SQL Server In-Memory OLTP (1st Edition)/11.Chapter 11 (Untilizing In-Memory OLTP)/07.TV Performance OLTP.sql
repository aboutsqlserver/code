/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*          07.Memory-Optimized Table Variable Performance (OLTP)           */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go


if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'TestTempVars') drop proc dbo.TestTempVars; 
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'TestTempTables') drop proc dbo.TestTempTables; 
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'TestInMemTempTables') drop proc dbo.TestInMemTempTables; 
if exists(select * from sys.table_types t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'InMemTV') drop type dbo.InMemTV; 
go

create type dbo.InMemTV as table
(
	Id int not null
		primary key nonclustered hash
		with (bucket_count=512),
	Placeholder char(255)
)
with (memory_optimized=on)
go

create proc dbo.TestInMemTempTables(@Rows int)
as
	declare
		@ttTemp dbo.InMemTV
		,@Cnt int

	;with N1(C) as (select 0 union all select 0) -- 2 rows
	,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
	,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
	,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
	,Ids(Id) as (select row_number() over (order by (select null)) from N4)
	insert into @ttTemp	(Id)
		select Id from Ids where Id <= @Rows;

	select @Cnt = count(*) from @ttTemp 
go


create proc dbo.TestTempTables(@Rows int)
as
	declare
		@Cnt int

	create table #TTTemp
	(
		Id int not null primary key,
		Placeholder char(255)
	)

	;with N1(C) as (select 0 union all select 0) -- 2 rows
	,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
	,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
	,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
	,Ids(Id) as (select row_number() over (order by (select null)) from N4)
	insert into #TTTemp	(Id)
		select Id from Ids where Id <= @Rows;

	select @Cnt = count(*) from #TTTemp
go


create proc dbo.TestTempVars(@Rows int)
as
	declare
		@Cnt int

	declare 
		@ttTemp table
		(
			Id int not null primary key,
			Placeholder char(255)
		)

	;with N1(C) as (select 0 union all select 0) -- 2 rows
	,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
	,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
	,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
	,Ids(Id) as (select row_number() over (order by (select null)) from N4)
	insert into @ttTemp	(Id)
		select Id from Ids where Id <= @Rows;

	select @Cnt = count(*) from @ttTemp 
go

declare
	@Result table
	(
		[Rows] int not null primary key,
		InMemTV int not null,
		TempTbl int not null,
		OnDiskTV int not null
	);

declare
	@PacketSize int = 16
	,@LoopCnt int = 5000
	,@I int = 0
	,@DT datetime
	,@InMemTV int
	,@TempTbl int
	,@OnDiskTV int 

while @PacketSize <= 256
begin
	select @DT = getDate(), @I = 0;
	while @I < @LoopCnt
	begin
		exec dbo.TestInMemTempTables @PacketSize;
		set @I += 1;
	end;
	select @InMemTV = datediff(millisecond,@DT,GetDate());
	
	select @I = 0, @DT = getdate();
	while @I < @LoopCnt
	begin
		exec dbo.TestTempTables @PacketSize;
		set @I += 1;
	end;
	select @TempTbl = datediff(millisecond,@DT,GetDate());
	
	select @I = 0, @DT = getdate();
	while @I < @LoopCnt
	begin
		exec dbo.TestTempVars @PacketSize;
		set @I += 1;
	end;
	select @OnDiskTV = datediff(millisecond,@DT,GetDate());

	insert into @Result([Rows],InMemTV,TempTbl,OnDiskTV)
	values(@PacketSize,@InMemTV,@TempTbl,@OnDiskTV);
	select @PacketSize *= 2;
end;

select * from @Result order by [Rows];
go

/* Checking Cardinality Estimations */
declare
	@InMemTV dbo.InMemTV;

declare 
	@ttTemp table
	(
		Id int not null primary key,
		Placeholder char(255)
	);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as t1 cross join N1 as t2) -- 4 rows
,N3(C) as (select 0 from N2 as t1 cross join N2 as t2) -- 16 rows
,N4(C) as (select 0 from N3 as t1 cross join N3 as t2) -- 256 rows
,Ids(Id) as (select row_number() over (order by (select null)) from N4)
insert into @InMemTV(Id)
	select Id from Ids;

insert into @ttTemp 
	select * from @InMemTV;

select count(*) from @ttTemp; -- option (recompile);
select count(*) from @InMemTV; -- option (recompile);