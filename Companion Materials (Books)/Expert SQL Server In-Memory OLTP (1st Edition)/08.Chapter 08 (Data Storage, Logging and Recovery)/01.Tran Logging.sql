/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 08: Data Storage, Logging and Recovery              */
/*                        01.Transaction Logging                            */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'HKData' and s.name = 'dbo') drop table dbo.HKData;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'DiskData' and s.name = 'dbo') drop table dbo.DiskData;
go

create table dbo.HKData
(
	ID int not null,
	Col int not null,
	
	constraint PK_HKData
	primary key nonclustered hash(ID) 
	with (bucket_count=64),
)
with (memory_optimized=on, durability=schema_and_data)  
go

checkpoint
go

/*** Creating Transaction Record ***/
declare
	@I int = 1

begin tran 
	while @I <= 50
	begin
		insert into dbo.HKData with (snapshot)
		(ID, Col)
		values(@I, @I)
		
		set @I += 1
	end
commit
go

/*** Analyzing Tran Log Content ***/
select *
from sys.fn_dblog(NULL, NULL)
order by [Current LSN] desc;
go


/*** Analyzing Output of LOP_HK Record ***/
select [Current LSN], object_name(table_id) as [Table]
	,operation_desc, tx_end_timestamp, total_size
from sys.fn_dblog_xtp(<Use LSN of LOP_HK operation from result of sys.fn_dblog>, 
	<Use LSN of LOP_HK operation from result of sys.fn_dblog>)
go

create table dbo.DiskData
(
	ID int not null,
	Col int not null,
	
	constraint PK_DiskData
	primary key nonclustered(ID) 
)
go

checkpoint
go

declare
	@I int = 1

begin tran
	while @I <= 500
	begin
		insert into dbo.DiskData(ID, Col)
		values(@I, @I)
			
		set @I += 1
	end
commit
go

select *
from sys.fn_dblog(NULL, NULL)
order by [Current LSN] desc;
go



