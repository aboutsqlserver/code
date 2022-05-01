/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*            Chapter 36. Transaction Processing in In-Memory OLTP          */
/*                           Transaction Logging                            */
/****************************************************************************/

set noexec off
go

set nocount on
go

if convert(int,
	left(
		convert(nvarchar(128), serverproperty('ProductVersion')),
		charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
	)
) < 12 
begin
	raiserror('You should have SQL Server 2014-2016 to execute this script',16,1) with nowait
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3 or charindex('X64',@@Version) = 0
begin
	raiserror('That script requires 64-Bit Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

if not exists (select * from sys.databases where name = 'SQLServerInternalsHK')
begin
	raiserror('Create [SQLServerInternalsHK] database with "02.Create In-Memory OLTP DB.sql" script from "00.Init" project',16,1)
	set noexec on
end
go

use SQLServerInternalsHK
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'MOTable') drop table dbo.MOTable;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'DiskTable') drop table dbo.DiskTable;
go


create table dbo.MOTable
(
	ID int not null,
	Col int not null,
	
	constraint PK_MOTable
	primary key nonclustered hash(ID) 
	with (bucket_count=1024),
)
with (memory_optimized=on, durability=schema_and_data);
go

checkpoint
go

/*** Creating Transaction Record ***/
declare
	@I int = 1

begin tran 
	while @I <= 500
	begin
		insert into dbo.MOTable with (snapshot)
		(ID, Col)
		values(@I, @I);
		
		set @I += 1;
	end
commit
go

/*** Analyzing Tran Log Content ***/
select *
from sys.fn_dblog(NULL, NULL)
order by [Current LSN] desc;
go


/*** Analyzing Output of LOP_HK Record ***/
select [Current LSN], operation_desc, tx_end_timestamp, total_size, *
--from sys.fn_dblog_xtp('0x00000024:00000e18:0002', '0x00000024:00000e18:0002');
from sys.fn_dblog_xtp(<Use LSN of LOP_HK operation from result of sys.fn_dblog>, <Use LSN of LOP_HK operation from result of sys.fn_dblog>)
go

create table dbo.DiskTable
(
    ID int not null,
    Col int not null,
    constraint PK_DiskTable primary key nonclustered(ID) 
);

declare
    @I int = 1

begin tran
    while @I <= 500
    begin
        insert into dbo.DiskTable(ID, Col) values(@I, @I);
        set @I += 1;
    end
commit;
go

/*** Analyzing Tran Log Content ***/
select *
from sys.fn_dblog(NULL, NULL)
order by [Current LSN] desc;
go

