/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*             Chapter 04. Special Indexng and Storage Feautes              */
/*                            Row Compression                               */
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
	raiserror('This script requires SQL Server 2008+ to execute',16,1) with nowait
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3 
begin
	raiserror('That script requires Enterprise or Developer Editions',16,1)
	set noexec on
end
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'RowCompressionData') drop table dbo.RowCompressionData;
go

create table dbo.RowCompressionData
(
	Int1 int,
	Int2 int,
	Int3 int,
	VarChar1 varchar(1000),
	VarChar2 varchar(1000),
	Bit1 bit,
	Bit2 bit,
	Char1 char(1000),
	Char2 char(1000),
	Char3 char(1000)
)
with (data_compression=row);

insert into dbo.RowCompressionData
values
	(0 /*Int1*/, 2147483647 /*Int2*/, null /*Int3*/
	,'aaa'/*VarChar1*/,replicate('b',1000) /*VarChar2*/
	,0 /*BitCol1*/, 1 /*BitCol2*/, null /*Char1*/
	, replicate('c',1000) /*Char2*/
	,'dddddddddd' /*Char3*/);
go

dbcc ind
(
	'SQLServerInternals' /*Database Name*/
	,'dbo.RowCompressionData' /*Table Name*/
	,-1 /*Display information for all pages of all indexes*/
);

-- SQL Server 2012+
select object_id, index_id, partition_id, allocation_unit_type_desc as [Type], is_allocated
	,is_iam_page, page_type, page_type_desc, allocated_page_file_id as [FileId]
    ,allocated_page_page_id as [PageId], rowset_id, allocation_unit_id
from sys.dm_db_database_page_allocations(db_id(), object_id('dbo.RowCompressionData'),null, NULL, 'DETAILED')
where is_allocated = 1
order by index_id, partition_id;

-- Redirecting DBCC PAGE output to console
dbcc traceon(3604)
dbcc page
(
	'SqlServerInternals' /*Database Name*/
	,3 /*File ID*/
	,<> /*Page ID - Replace with PageId from DBCC IND output */ 
	,3 /*Output mode: 3 - display page header and row details */
);	
