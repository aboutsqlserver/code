/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    Chapter 34. Columnstore Indexes                       */
/*                       DMVs in SQL Server 2016                            */
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
) < 13 
begin
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

drop table if exists dbo.CITable
go

create table dbo.CITable
(
	Col1 int not null,
	Col2 int not null,
	Col3 int not null
);

insert into dbo.CITable(Col1, Col2, Col3)
values(1,1,1), (2,2,2);

create clustered columnstore index CCI_CITable on dbo.CITable; 

insert into dbo.CITable(Col1, Col2, Col3)
values(100,100,100),(200,200,200);

create nonclustered index IDX_CITable_Col3 on dbo.CITable(Col3);
go

-- SQL Server 2014 - 2016 
select *
from sys.column_store_row_groups
where object_id =  object_id(N'dbo.CITable');
go

-- SQL Server 2016 
select *
from sys.dm_db_column_store_row_group_physical_stats
where object_id =  object_id(N'dbo.CITable');
go

-- SQL Server 2016 
select *
from sys.dm_db_column_store_row_group_operational_stats
where object_id =  object_id(N'dbo.CITable');
go

-- SQL Server 2016 
select *
from sys.internal_partitions ip 
where ip.object_id = object_id(N'dbo.CITable');
go
