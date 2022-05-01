/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 01. Data Storage Internals                     */
/*                       Examining Data Row Format                          */
/****************************************************************************/

use [SqlServerInternals]
go

-- IN-ROW data
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'DataRows') drop table dbo.DataRows;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'RowOverflow') drop table dbo.RowOverflow;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'LOBData') drop table dbo.LOBData;
go

create table dbo.DataRows
(
	ID int not null,
	Col1 varchar(255) null,
	Col2 varchar(255) null,
	Col3 varchar(255) null
);

insert into dbo.DataRows(ID, Col1, Col3)  values (1,replicate('a',255),replicate('c',255));
insert into dbo.DataRows(ID, Col2) values (2,replicate('b',255));
go

-- You have two options to get allocation information: DBCC IND and sys.dm_db_database_page_allocations (SQL Server 2012+)
dbcc ind
(
	'SQLServerInternals' /*Database Name*/
	,'dbo.DataRows' /*Table Name*/
	,-1 /*Display information for all pages of all indexes*/
);

-- SQL Server 2012+
select object_id, index_id, partition_id, allocation_unit_type_desc as [Type], is_allocated
	,is_iam_page, page_type, page_type_desc, allocated_page_file_id as [FileId]
    ,allocated_page_page_id as [PageId], rowset_id, allocation_unit_id
from sys.dm_db_database_page_allocations
            (db_id(), object_id('dbo.DataRows'),null, NULL, 'DETAILED')
order by 
    index_id, partition_id;

-- Redirecting DBCC PAGE output to console
dbcc traceon(3604)
dbcc page
(
	'SqlServerInternals' /*Database Name*/
	,3 /*File ID*/
	,<> /*Page ID - Replace with PageId from DBCC IND output */ 
	,3 /*Output mode: 3 - display page header and row details */
);	


-- ROW-OVERFLOW data
create table dbo.RowOverflow
(
	ID int not null,
	Col1 varchar(8000) null,
	Col2 varchar(8000) null
);

insert into dbo.RowOverflow(ID, Col1, Col2) 
values (1,replicate('a',8000),replicate('b',8000));

dbcc ind
(
	'SQLServerInternals' /*Database Name*/
	,'dbo.RowOverflow' /*Table Name*/
	,-1 /*Display information for all pages of all indexes*/
);

-- SQL Server 2012+
select object_id, index_id, partition_id, allocation_unit_type_desc as [Type], is_allocated
	,is_iam_page, page_type, page_type_desc, allocated_page_file_id as [FileId]
    ,allocated_page_page_id as [PageId], rowset_id, allocation_unit_id
from sys.dm_db_database_page_allocations(db_id(), object_id('dbo.RowOverflow'),null, NULL, 'DETAILED')
order by 
    index_id, partition_id;

dbcc page
(
	'SqlServerInternals' /*Database Name*/
	,3 /*File ID*/
	,<> /*Page ID - Replace with PageId from DBCC IND output */ 
	,3 /*Output mode: 3 - display page header and row details */
);

-- LOB-DATA data
create table dbo.LOBData
(
	ID int not null,
	Col1 varchar(max) null
);

insert into dbo.LOBData(ID, Col1) 
values (1, replicate(convert(varchar(max),'a'),16000));


dbcc ind
(
	'SQLServerInternals' /*Database Name*/
	,'dbo.LOBData' /*Table Name*/
	,-1 /*Display information for all pages of all indexes*/
);


-- SQL Server 2012+
select object_id, index_id, partition_id, allocation_unit_type_desc as [Type], is_allocated
	,is_iam_page, page_type, page_type_desc, allocated_page_file_id as [FileId]
    ,allocated_page_page_id as [PageId], rowset_id, allocation_unit_id
from sys.dm_db_database_page_allocations(db_id(), object_id('dbo.LOBData'),null, NULL, 'DETAILED')
order by 
    index_id, partition_id;

dbcc page
(
	'SqlServerInternals' /*Database Name*/
	,3 /*File ID*/
	,<> /*Page ID - Replace with PageId from DBCC IND output */ 
	,3 /*Output mode: 3 - display page header and row details */
);

