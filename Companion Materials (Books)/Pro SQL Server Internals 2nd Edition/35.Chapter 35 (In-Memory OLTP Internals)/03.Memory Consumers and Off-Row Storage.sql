/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                  Chapter 35. In-Memory OLTP Internals                    */
/*                  Memory Consumers and Off-Row Storage                    */
/****************************************************************************/

set noexec off
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

if convert(int, serverproperty('EngineEdition')) != 3 or charindex('X64',@@Version) = 0
begin
	raiserror('That script requires 64-Bit Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

if not exists (select * from sys.databases where name = 'SQLServerInternalsHK')
begin
	raiserror('Create [SQLServerInternalsHK] database with "02.Create In-Memory OLTP DB.sql" script from "00.Init" project',16,1);
	set noexec on
end
go

use SQLServerInternalsHK
go

drop table if exists dbo.MemoryConsumersOffRow;
go

create table dbo.MemoryConsumersOffRow
(
	ID int not null
		constraint PK_MemoryConsumersOffRow
		primary key nonclustered hash with (bucket_count=1024),
	Name varchar(256) not null,
	RowOverflowCol varchar(8000),
	LOBCol varchar(max),

	index IDX_Name nonclustered(Name)
)
with (memory_optimized=on, durability=schema_only);

select 
	i.name as [Index], i.index_id, a.xtp_object_id, a.type_desc, a.minor_id
	,c.memory_consumer_id, c.memory_consumer_type_desc as [mc type]
	,c.memory_consumer_desc as [description], c.allocation_count as [allocs]
	,c.allocated_bytes, c.used_bytes
from 
	sys.dm_db_xtp_memory_consumers c join
		sys.memory_optimized_tables_internal_attributes a on
			a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id
	left outer join sys.indexes i on
		c.object_id = i.object_id and 
		c.index_id = i.index_id and
		a.minor_id = 0 
where
	c.object_id = object_id('dbo.MemoryConsumersOffRow');
