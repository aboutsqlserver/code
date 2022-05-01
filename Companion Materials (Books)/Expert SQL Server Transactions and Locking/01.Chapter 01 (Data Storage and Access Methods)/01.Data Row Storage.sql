/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    01.Data Storage and Access Methods                    */
/*                            Data Row Storage                              */
/****************************************************************************/

use SQLServerInternals
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'DataRows') drop table dbo.DataRows;
go

create table dbo.DataRows
(
	ID int not null,
	ADate datetime not null,
	VarCol1 varchar(max),
	VarCol2 varchar(5000),
	VarCol3 varchar(5000)
);

insert into dbo.DataRows(ID, ADate, VarCol1, VarCol2, VarCol3)
values
(
	1 -- ID
	,'1974-08-24' -- ADate
	,replicate(convert(varchar(max),'A'),32000) -- VarCol1
	,replicate(convert(varchar(max),'B'),5000)	-- VarCol2
	,replicate(convert(varchar(max),'A'),5000)	-- VarCol3
);
go

select
	index_id, partition_number, alloc_unit_type_desc, page_count
	,record_count, min_record_size_in_bytes, max_record_size_in_bytes
	,avg_record_size_in_bytes
	,'',''
from 
	sys.dm_db_index_physical_stats
	(
		db_id()
		,object_id(N'dbo.DataRows')
		,0		-- IndexId = 0 -> Table Heap
		,NULL	-- All Partitions
		,'DETAILED'
	);
go

insert into dbo.DataRows(ID, ADate, VarCol1, VarCol2, VarCol3)
values
(
	2				-- ID
	,'2006-09-29'	-- ADate
	,'DDDDD'		-- VarCol1
	,'EEEEE'		-- VarCol2
	,'FFFFF'		-- VarCol3
);
go


select
	index_id, partition_number, alloc_unit_type_desc, page_count
	,record_count, min_record_size_in_bytes, max_record_size_in_bytes
	,avg_record_size_in_bytes
	,'',''

from 
	sys.dm_db_index_physical_stats
	(
		db_id()
		,object_id(N'dbo.DataRows')
		,0		-- IndexId = 0 -> Table Heap
		,NULL	-- All Partitions
		,'DETAILED'
	);
go