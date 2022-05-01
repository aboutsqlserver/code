/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    01.Data Storage and Access Methods                    */
/*                         Forwarding Pointers                              */
/****************************************************************************/

use SQLServerInternals
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'ForwardingPointers') drop table dbo.ForwardingPointers;
go

create table dbo.ForwardingPointers
(
	ID int not null,
	Val varchar(8000) null
);

insert into dbo.ForwardingPointers(ID,Val) values (1,null);
insert into dbo.ForwardingPointers(ID,Val) values (2,replicate('2',7800));
insert into dbo.ForwardingPointers(ID,Val) values (3,null);

select page_count, avg_record_size_in_bytes, avg_page_space_used_in_percent, forwarded_record_count
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.ForwardingPointers'),0,null,'DETAILED');

set statistics io on
select count(*) from dbo.ForwardingPointers;
set statistics io off
go

update dbo.ForwardingPointers set Val = replicate('1',5000) where ID = 1;
update dbo.ForwardingPointers set Val = replicate('3',5000) where ID = 3;

select page_count, avg_record_size_in_bytes, avg_page_space_used_in_percent, forwarded_record_count
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.ForwardingPointers'),0,null,'DETAILED');

set statistics io on
select count(*) from dbo.ForwardingPointers;
set statistics io off
