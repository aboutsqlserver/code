/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    01.Data Storage and Access Methods                    */
/*                     SARGability and Data Types                           */
/****************************************************************************/

use SQLServerInternals
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Data') drop table dbo.Data;
go

create table dbo.Data
(
	VarcharKey varchar(10) not null,
	Placeholder char(200)
);

create unique clustered index IDX_Data_VarcharKey
on dbo.Data(VarcharKey);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.Data(VarcharKey)
	select convert(varchar(10),ID)
	from IDs;
go


-- Enable "Include Actual Execution Plan"
declare
	@IntParam int

select @IntParam = '200';

select * from dbo.Data where VarcharKey = @IntParam;
select * from dbo.Data where VarcharKey = convert(varchar(10),@IntParam);
go

select * from dbo.Data where VarcharKey = '200';
select * from dbo.Data where VarcharKey = N'200'; -- unicode parameter
go

