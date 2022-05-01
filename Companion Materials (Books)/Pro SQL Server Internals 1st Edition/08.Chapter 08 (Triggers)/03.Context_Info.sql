/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                          Chapter 08. Triggers                            */
/*                             Context_Infp()                               */
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
		s.name = 'dbo' and t.name = 'Audit'    
)
	drop table dbo.Audit
go

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


create table dbo.Data
(
	ID int not null,
	Value int not null,

	constraint PK_Data
	primary key clustered(ID)
)
go

insert into dbo.data(ID, Value) values(1,1)
go


create table dbo.Audit
(
	ID int not null identity(1,1),
	OnDate datetime not null	
		constraint DEF_Audit_OnDate
		default getdate(),
	Info varchar(max),

	constraint PK_Audit
	primary key clustered(ID)
)
go

create trigger trgDataAU on dbo.Data
after update
as
begin
	-- if @@rowcount = 0 return
	set nocount on
	-- if not exists(select * from inserted i join deleted d on i.ID = d.ID) return
	declare
		@Info varchar(128)
		
	select @Info = convert(varchar(128),context_info())

	insert into dbo.Audit(Info)
	values(@Info)
end
go

declare 
	@V varbinary(128) 

select @V = convert(varbinary(128), 'I SHOULD NOT USE TRIGGERS')

set context_info @V

update dbo.Data set value = -1 where ID is null
select * from dbo.audit
go

update dbo.Data set value = -1 where ID = 1
select * from dbo.audit
go
