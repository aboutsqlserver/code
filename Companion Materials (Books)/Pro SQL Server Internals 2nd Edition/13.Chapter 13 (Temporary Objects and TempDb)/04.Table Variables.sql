/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. Temporary Objects and TempDB                   */
/*                            Table Variables                               */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go


create table #TT(ID int not null primary key);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N4)
insert into #TT(ID)
	select ID from IDs;
go


-- Enable "Include Actual Execution Plan"
-- Check Actual vs. Estimated # of rows
declare 
	@TTV table(ID int not null primary key);

insert into @TTV(ID)
	select ID from #TT;

select count(*) from #TT;
select count(*) from @TTV;
select count(*) from @TTV option (recompile);
go

declare 
	@TTV table(ID int not null primary key);

insert into @TTV(ID)
	select ID from #TT;

select count(*) from #TT;
select count(*) from @TTV;
select count(*) from @TTV option (recompile);
go


declare 
	@TTV table(ID int not null primary key);

insert into @TTV(ID)
	select ID from #TT;

select count(*) from #TT where ID > 0;
select count(*) from @TTV where ID > 0;
select count(*) from @TTV where ID > 0 option (recompile);
go

drop table #TT;
go