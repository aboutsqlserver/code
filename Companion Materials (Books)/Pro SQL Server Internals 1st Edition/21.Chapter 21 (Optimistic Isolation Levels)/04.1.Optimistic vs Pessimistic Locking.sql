/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                 Chapter 21. Optimistic Isolation Levels				    */
/*             Optimistic vs. Pessimistic Locking (Session 1)               */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Colors'    
)
	drop table dbo.Colors
go

/*** Enabling snapshot ***/
alter database SqlServerInternals 
set allow_snapshot_isolation on 
go

create table dbo.Colors
(
	Id int not null,
	Color char(5) not null
)
go

insert into dbo.Colors(Id, Color) values(1,'Black'),(2,'White')
go


/*** Test 1: Pessimistic Locking ***/
-- Step 1 -- starting transaction
set transaction isolation level read committed
begin tran
	update dbo.Colors
	set Color = 'White'
	where Color = 'Black'

	-- Run Session 2 code
commit
go

-- Both rows would have the same color
select * from dbo.Colors
go



/*** Test 2: Optimistic Locking ***/
-- Reset data
truncate table dbo.Colors;
insert into dbo.Colors(Id, Color) values(1,'Black'),(2,'White')
go

-- Step 1 -- starting transaction
set transaction isolation level snapshot
begin tran
	update dbo.Colors
	set Color = 'White'
	where Color = 'Black'

	-- Run Session 2 code
commit
go

-- Both rows would switch color
select * from dbo.Colors
go



/*** Disabling Snapshot ***/
alter database SqlServerInternals 
set allow_snapshot_isolation off
go
