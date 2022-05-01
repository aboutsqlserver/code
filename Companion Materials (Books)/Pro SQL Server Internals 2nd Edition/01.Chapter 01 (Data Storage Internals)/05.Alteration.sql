/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 01. Data Storage Internals                     */
/*                              Alteration                                  */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'AlterDemo') drop table dbo.AlterDemo;
go

create table dbo.AlterDemo
(
	ID int not null,
	Col1 int null,
	Col2 bigint null,
	Col3 char(10) null,
	Col4 tinyint null
);

select 
	c.column_id, c.Name, ipc.leaf_offset as [Offset in Row]
	,ipc.max_inrow_length as [Max Length], ipc.system_type_id as [Column Type]
from 
	sys.system_internals_partition_columns ipc join sys.partitions p on
		ipc.partition_id = p.partition_id
	join sys.columns c on
		c.column_id = ipc.partition_column_id and 
		c.object_id = p.object_id
where 
	p.object_id = object_id(N'dbo.AlterDemo')
order by 
	c.column_id;
go

alter table dbo.AlterDemo drop column Col1;
alter table dbo.AlterDemo alter column Col2 tinyint;
alter table dbo.AlterDemo alter column Col3 char(1);
alter table dbo.AlterDemo alter column Col4 int;
go

select 
	c.column_id, c.Name, ipc.leaf_offset as [Offset in Row]
	,ipc.max_inrow_length as [Max Length], ipc.system_type_id as [Column Type]
from 
	sys.system_internals_partition_columns ipc join sys.partitions p on
		ipc.partition_id = p.partition_id
	join sys.columns c on
		c.column_id = ipc.partition_column_id and 
		c.object_id = p.object_id
where 
	p.object_id = object_id(N'dbo.AlterDemo')
order by 
	c.column_id;
go


-- This script creates and drops clustered index for compatibility with SQL Server 2005. 

-- In SQL Server 2008+ you can should use: alter table dbo.AlterDemo rebuild, which
-- introduce less overhead (single table rebuild vs. two rebuilds
create unique clustered index I1 on dbo.AlterDemo(ID);
drop index I1 on dbo.AlterDemo;
go

select 
	c.column_id, c.Name, ipc.leaf_offset as [Offset in Row]
	,ipc.max_inrow_length as [Max Length], ipc.system_type_id as [Column Type]
from 
	sys.system_internals_partition_columns ipc join sys.partitions p on
		ipc.partition_id = p.partition_id
	join sys.columns c on
		c.column_id = ipc.partition_column_id and 
		c.object_id = p.object_id
where 
	p.object_id = object_id(N'dbo.AlterDemo')
order by 
	c.column_id;



