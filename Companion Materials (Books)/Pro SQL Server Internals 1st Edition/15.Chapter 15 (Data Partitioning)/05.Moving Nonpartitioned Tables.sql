/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                      Chapter 15. Data Partitioning                       */
/*             Moving Non-Partitioned Table Between Filegroups              */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*			This script requires Enterprise Edition of SQL Server.			*/
/*	    You can rebuild indexes to different filegroups in non-Enterprise   */ 
/*                             Editions offline			                    */
/****************************************************************************/

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'RegularTable' and s.name = 'dbo'
)
	drop table dbo.RegularTable
go

if exists(
	select *
	from sys.partition_schemes 
	where name = 'psRegularTable'
)
	drop partition scheme psRegularTable
go


if exists(
	select *
	from sys.partition_functions
	where name = 'pfRegularTable'
)
	drop partition function pfRegularTable
go


create table dbo.RegularTable
(
	OrderDate datetime not null,
	OrderId int not null identity(1,1),
	OrderNum varchar(32) not null,
	LobColumn varchar(max) null,
	Placeholder char(50) null,
) textimage_on [FASTSTORAGE];

create unique clustered index IDX_RegularTable_OrderDate_OrderId
on dbo.RegularTable(OrderDate, OrderId)
on [FASTSTORAGE];
go

select 
	p.partition_number as [Partition]
	,object_name(p.object_id) as [Table]
	,filegroup_name(a.data_space_id) as [FileGroup]
	,a.type_desc as [Allocation Unit]
from 
	sys.partitions p join sys.allocation_units a on 
		p.partition_id = a.container_id
where 
	p.object_id = object_id('dbo.RegularTable')
order by 
	p.partition_number
go

-- You can perform online index rebuild in SQL Server 2012+
create unique clustered index IDX_RegularTable_OrderDate_OrderId
on dbo.RegularTable(OrderDate, OrderId)
with (drop_existing=on /*, online=on */)
on [FG2014]
go

select 
	p.partition_number as [Partition]
	,object_name(p.object_id) as [Table]
	,filegroup_name(a.data_space_id) as [FileGroup]
	,a.type_desc as [Allocation Unit]
from 
	sys.partitions p join sys.allocation_units a on 
		p.partition_id = a.container_id
where 
	p.object_id = object_id('dbo.RegularTable')
order by 
	p.partition_number
go

/*** Workaround: Rebuilding table to partition function ***/
create partition function pfRegularTable(datetime)
as range right for values ('2100-01-01');

create partition scheme psRegularTable
as partition pfRegularTable
all to ([FG2014]);
go

-- You can perform online index rebuild in SQL Server 2012+
create unique clustered index IDX_RegularTable_OrderDate_OrderId
on dbo.RegularTable(OrderDate, OrderId)
with (drop_existing=on/*, online=on */)
on psRegularTable(OrderDate);

alter partition function pfRegularTable()
merge range('2100-01-01');
go

select 
	p.partition_number as [Partition]
	,object_name(p.object_id) as [Table]
	,filegroup_name(a.data_space_id) as [FileGroup]
	,a.type_desc as [Allocation Unit]
from 
	sys.partitions p join sys.allocation_units a on 
		p.partition_id = a.container_id
where 
	p.object_id = object_id('dbo.RegularTable')
order by 
	p.partition_number
go



