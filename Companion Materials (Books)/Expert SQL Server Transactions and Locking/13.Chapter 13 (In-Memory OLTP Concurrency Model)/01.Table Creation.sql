/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. In-Memory OLTP Concurrency Model               */
/*                           01.Table Creation                              */
/****************************************************************************/

set nocount on
go

use SQLServerInternalsHK
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'HKData') drop table dbo.HKData;
go

create table dbo.HKData
(
	ID int not null,
	Col int not null,
	
	constraint PK_HKData
	primary key nonclustered hash(ID) 
	with (bucket_count=64),
)
with (memory_optimized=on, durability=schema_only)  
go

insert into dbo.HKData(ID, Col) 
values(1,1),(2,2),(3,3),(4,4),(5,5);
go

