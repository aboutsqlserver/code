/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 10: Data Storage, Logging and Recovery              */
/*                        01.Transaction Logging                            */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists dbo.HKData;
drop table if exists dbo.DiskData;
go

create table dbo.HKData
(
	ID int not null,
	Col int not null,
	
	constraint PK_HKData
	primary key nonclustered hash(ID) 
	with (bucket_count=2048),
)
with (memory_optimized=on, durability=schema_and_data)  
go

checkpoint
go

/*** Creating Transaction Record ***/
declare
	@I int = 1

begin tran 
	while @I <= 500
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
where [Operation] like '%HK%'
order by [Current LSN] desc;
go


/*** Analyzing Output of LOP_HK Record ***/
select [Current LSN], xtp_object_id, operation_desc
    ,tx_end_timestamp, total_size
from sys.fn_dblog_xtp(null, null) 
-- <Use LSN of LOP_HK operation from result of sys.fn_dblog>
where [Current LSN] = '00000022:00000240:0035'
go

create table dbo.DiskData
(
	ID int not null,
	Col int not null,
	
	constraint PK_DiskData
	primary key nonclustered(ID) 
);

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



