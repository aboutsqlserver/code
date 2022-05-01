/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                   Chapter 01. Data Storage Internals                     */
/*                       Examining Data Row Format                          */
/****************************************************************************/

use [SqlServerInternals]
go

-- IN-ROW data
if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'DataRows'    
)
	drop table dbo.DataRows
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

dbcc ind
(
	'SQLServerInternals' /*Database Name*/
	,'dbo.DataRows' /*Table Name*/
	,-1 /*Display information for all pages of all indexes*/
);

-- Redirecting DBCC PAGE output to console
dbcc traceon(3604)
dbcc page
(
	'SqlServerInternals' /*Database Name*/
	,1 /*File ID*/
	,<> /*Page ID - Replace with PageId from DBCC IND output */ 
	,3 /*Output mode: 3 - display page header and row details */
);	


-- ROW-OVERFLOW data
if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'RowOverflow'    
)
	drop table dbo.RowOverflow
go

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

dbcc page
(
	'SqlServerInternals' /*Database Name*/
	,1 /*File ID*/
	,<> /*Page ID - Replace with PageId from DBCC IND output */ 
	,3 /*Output mode: 3 - display page header and row details */
);

-- LOB-DATA data
if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'TextData'    
)
	drop table dbo.TextData
go

create table dbo.TextData
(
	ID int not null,
	Col1 text null
);

insert into dbo.TextData(ID, Col1) 
values (1, replicate(convert(varchar(max),'a'),16000));


dbcc ind
(
	'SQLServerInternals' /*Database Name*/
	,'dbo.TextData' /*Table Name*/
	,-1 /*Display information for all pages of all indexes*/
);

dbcc page
(
	'SqlServerInternals' /*Database Name*/
	,1 /*File ID*/
	,<> /*Page ID - Replace with PageId from DBCC IND output */ 
	,3 /*Output mode: 3 - display page header and row details */
);

