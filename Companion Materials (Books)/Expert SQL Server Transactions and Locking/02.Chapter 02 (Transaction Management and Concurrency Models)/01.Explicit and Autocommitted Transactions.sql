/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              02.Transaction Management and Concurrency Models            */
/*                  Explicit and Autocommitted Transactions                 */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'TranOverhead') drop table dbo.TranOverhead;
go

create table dbo.TranOverhead
(
	Id int not null,
	Col char(50) null,
	constraint PK_TranOverhead
	primary key clustered(Id)
);
go

-- Autocommitted transactions
declare
	@Id int = 1,
	@StartTime datetime,
	@num_of_writes bigint,
	@num_of_bytes_written bigint

-- Log file statistics
select @num_of_writes = num_of_writes, @num_of_bytes_written = num_of_bytes_written
from sys.dm_io_virtual_file_stats(db_id(),2);

select @StartTime = getDate();

while @Id < 10000
begin
	insert into dbo.TranOverhead(Id, Col)
	values(@Id, 'A');

	update dbo.TranOverhead
	set Col = 'B'
	where Id = @Id;

	delete from dbo.TranOverhead
	where Id = @Id;

	set @Id += 1;
end;

select 
	datediff(millisecond, @StartTime, getDate()) as [Exec Time ms: Autocommitted Tran]
	,s.num_of_writes - @num_of_writes as [Number of writes]
	,(s.num_of_bytes_written - @num_of_bytes_written) / 1024 as [Bytes written (KB)]
from
	sys.dm_io_virtual_file_stats(db_id(),2) s;
go

-- Explicit Tran
declare
	@Id int = 1,
	@StartTime datetime,
	@num_of_writes bigint,
	@num_of_bytes_written bigint

-- Log file statistics
select @num_of_writes = num_of_writes, @num_of_bytes_written = num_of_bytes_written
from sys.dm_io_virtual_file_stats(db_id(),2);

select @StartTime = getDate();

while @Id < 10000
begin
	begin tran
		insert into dbo.TranOverhead(Id, Col)
		values(@Id, 'A');

		update dbo.TranOverhead
		set Col = 'B'
		where Id = @Id;

		delete from dbo.TranOverhead
		where Id = @Id;
	commit
	set @Id += 1;
end;

select 
	datediff(millisecond, @StartTime, getDate()) as [Exec Time ms: Explicit Tran]
	,s.num_of_writes - @num_of_writes as [Number of writes]
	,(s.num_of_bytes_written - @num_of_bytes_written) / 1024 as [Bytes written (KB)]
from
	sys.dm_io_virtual_file_stats(db_id(),2) s;
go