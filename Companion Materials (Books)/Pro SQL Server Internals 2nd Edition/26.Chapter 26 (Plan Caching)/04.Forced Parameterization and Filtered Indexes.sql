/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 26. Plan Caching                       */
/*                 Forced Parameterization and Filtered Indexes             */
/****************************************************************************/

set noexec off
go

use [SqlServerInternals]
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
		) < 10 -- SQL Server 2005
begin
	raiserror('This script requires SQL Server 2008+ to execute',16,1) with nowait;
	set noexec on
end
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'RawData') drop table dbo.RawData;
go

alter database SqlServerInternals set parameterization simple;
go


create table dbo.RawData
(
	RecId int not null identity(1,1), 
	Processed bit not null, 
	Placeholder char(100),
	constraint PK_RawData
	primary key clustered(RecId)
);

/* Inserting:
	Processed = 1: 65,536 rows
	Processed = 0: 16 rows */
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2 ) -- 65,536 rows
,Nums(Num) as (select row_number() over (order by (select null)) from N5)
insert into dbo.RawData(Processed)
	select 1
	from Nums;

insert into dbo.RawData(Processed)
	select 0
	from dbo.RawData
	where RecId <= 16;

create unique nonclustered index IDX_RawData_Processed_Filtered 
on dbo.RawData(RecId)
include(Processed)
where Processed = 0;
go

select count(*)
from dbo.RawData
where Processed = 0;			
go

alter database SqlServerInternals set parameterization forced;
go

select count(*)
from dbo.RawData
where Processed = 0;
go

alter database SqlServerInternals set parameterization simple;
go
