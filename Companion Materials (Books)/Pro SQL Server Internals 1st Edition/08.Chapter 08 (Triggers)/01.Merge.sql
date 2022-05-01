/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                          Chapter 08. Triggers                            */
/*                           Triggers and Merge                             */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/***              That script would not work in SQL Server 2005           ***/
/****************************************************************************/
if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Data'    
)
	drop table dbo.Data
go

create table dbo.Data(Col int not null)
go

create trigger trg_Data_AI on dbo.Data
after insert 
as
	select 
		'After Insert' as [Trigger]
		,@@RowCount as [RowCount]
		,(select count(*) from inserted) as [Inserted Cnt]
		,(select count(*) from deleted) as [Deleted Cnt]
go

create trigger trg_Data_AU on dbo.Data
after update
as
	select 
		'After Update' as [Trigger]
		,@@RowCount as [RowCount]
		,(select count(*) from inserted) as [Inserted Cnt]
		,(select count(*) from deleted) as [Deleted Cnt]
go

create trigger trg_Data_AD on dbo.Data
after delete
as
	select 
		'After Delete' as [Trigger]
		,@@RowCount as [RowCount]
		,(select count(*) from inserted) as [Inserted Cnt]
		,(select count(*) from deleted) as [Deleted Cnt]
go

merge into dbo.Data as Target
using (select 1 as [Value]) as Source
on Target.Col = Source.Value
when not matched by target then
	insert(Col) values(Source.Value)
when not matched by source then
	delete
when matched then
	update set Col = Source.Value;
go

-- The right way of writing triggers
alter trigger trg_Data_AI on dbo.Data
after insert 
as
	if @@rowcount = 0 
		return
	set nocount on
	if exists(select * from inserted)
		/* Some Code Here */   
		return   
go

alter trigger trg_Data_AU on dbo.Data
after update
as
	if @@rowcount = 0 
		return
	set nocount on
	if	exists(select * from inserted) and 
		exists(select * from deleted)
		/* Some Code Here */   
		return   
go

alter trigger trg_Data_AD on dbo.Data
after delete
as
	if @@rowcount = 0 
		return
	set nocount on
	if	exists(select * from deleted)
		/* Some Code Here */
		return
go
        