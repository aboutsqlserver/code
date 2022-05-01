/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    Chapter 34. Columnstore Indexes                       */
/*                       DMVs in SQL Server 2014                            */
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
	) < 12 
begin
	raiserror('You should have SQL Server 2014 to execute this script',16,1) with nowait;
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'CITable') drop table dbo.CITable;
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
go

-- SQL Server 2014 - 2016 
select *
from sys.column_store_row_groups
where object_id =  object_id(N'dbo.CITable');
go

