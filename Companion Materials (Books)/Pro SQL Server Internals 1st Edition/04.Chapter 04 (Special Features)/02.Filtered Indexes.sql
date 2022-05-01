/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*             Chapter 04. Special Indexng and Storage Feautes              */
/*                            Filtered Indexes                              */
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
		s.name = 'dbo' and t.name = 'Data'    
)
	drop table dbo.data
go

create table dbo.Data
(
	RecId int not null,
	Processed bit not null,
	/* Other Columns */
);

create unique clustered index IDX_Data_RecId on dbo.Data(RecId);
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.Data(RecId, Processed)
	select ID, 0
	from Ids;
go

create nonclustered index IDX_Data_Unprocessed_Filtered
on dbo.Data(RecId)
include(Processed)
where Processed = 0;
go

update dbo.Data set Processed = 1;

-- Statement below requires SQL Server 2008R2 SP2+ or SQL Server 2012 SP1+ to execute
select
	s.stats_id as [Stat ID]
	,sc.name + '.' + t.name as [Table]
	,s.name as [Statistics]
	,p.last_updated
	,p.rows
	,p.rows_sampled
	,p.modification_counter as [Mod Count]
from
	sys.stats s join sys.tables t on 
		s.object_id = t.object_id
	join sys.schemas sc on
		t.schema_id = sc.schema_id
	outer apply
		sys.dm_db_stats_properties(t.object_id,s.stats_id) p
where	
	sc.name = 'dbo' and t.name = 'Data'
go

