/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 05. Deadlocks				            */
/*                  Deadlock Due to Multiple Updates (Session 1)            */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Data') drop table dbo.Data;
go

create table dbo.Data
(
	ID int not null,
	Value int not null,
	ModTime datetime not null,

	constraint PKData
	primary key clustered(ID)
)
go

create unique nonclustered index IDX_Data_ModTime
on dbo.Data(ModTime, ID);
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N4)
insert into dbo.Data(ID, Value, ModTime)
	select ID, ID, GetDate()
	from IDs
go

create trigger trgData_AU on dbo.Data
after update
as
	if @@rowcount = 0
		return;
	set nocount on
	if	not exists(select * from inserted) and 
		not exists(select * from deleted)
		return;
	-- adding delay to emulate concurrent activity
	waitfor delay '00:00:15.000';

	update t
	set
		ModTime = GetDate()
	from
		dbo.Data t join inserted i on
			t.ID = i.ID;
go


-- Run session 2 code while trigger is running
update dbo.Data
set Value = -1
where ID = 1;