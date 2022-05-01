/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*             Chapter 04. Special Indexng and Storage Feautes              */
/*                           Row Compression                                */
/****************************************************************************/

use [SqlServerInternals]
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'RowCompressionData'    
)
	drop table dbo.RowCompressionData
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

-- Redirecting DBCC PAGE output to console
dbcc traceon(3604)
dbcc page
(
	'SqlServerInternals' /*Database Name*/
	,1 /*File ID*/
	,<> /*Page ID - Replace with PageId from DBCC IND output */ 
	,3 /*Output mode: 3 - display page header and row details */
);	
