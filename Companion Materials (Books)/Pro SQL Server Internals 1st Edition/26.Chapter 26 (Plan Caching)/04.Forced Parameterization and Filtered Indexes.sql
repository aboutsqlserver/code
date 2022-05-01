/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                           Chapter 26. Plan Caching                       */
/*                 Forced Parameterization and Filtered Indexes             */
/****************************************************************************/

set noexec off
go

set nocount on
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
	raiserror('This script requires SQL Server 2008+ to execute',16,1) with nowait
	set noexec on
end
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'RawData'    
)
	drop table dbo.RawData
go

alter database SqlServerInternals set parameterization simple
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
;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 rows
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2 ) -- 65,536 rows
,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)
insert into dbo.RawData(Processed)
	select 1
	from Ids;

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
where Processed = 0			
go

alter database SqlServerInternals set parameterization forced
go

select count(*)
from dbo.RawData
where Processed = 0
go

alter database SqlServerInternals set parameterization simple
go
