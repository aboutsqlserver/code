/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 07: In-Memory OLTP Concurrency Model                */
/*                             01.Table Creation                            */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'HKData' and s.name = 'dbo') drop table dbo.HKData;
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

