/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                           Chapter 09. Views                              */
/*                  Supporting Uniqueness with Indexed Views                */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/***    In SQL Server 2008+ Filtered Indexes is the the better option     ***/
/****************************************************************************/

if exists
(
	select * 
	from sys.views v join sys.schemas s on
		v.schema_id = s.schema_id
	where
		s.name = 'dbo' and v.name = 'vClientsUniqueSSN'    
)
	drop view dbo.vClientsUniqueSSN
go


if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Clients09'    
)
	drop table dbo.Clients09
go

create table dbo.Clients09
(
	ClientId int not null,
	Name nvarchar(128) not null,
	SSN varchar(11) null
)
go

create view dbo.vClientsUniqueSSN(SSN)
with schemabinding
as
	select SSN from dbo.Clients09 where SSN is not null
go
	
create unique clustered index IDX_vClientsUniqueSSN_SSN 
on dbo.vClientsUniqueSSN(SSN)
go

insert into dbo.Clients09(ClientId, Name, SSN)
values(1,'John', null)
go

insert into dbo.Clients09(ClientId, Name, SSN)
values(2,'Ann', null)
go

insert into dbo.Clients09(ClientId, Name, SSN)
values(3,'Peter', '123-45-6789')
go

insert into dbo.Clients09(ClientId, Name, SSN)
values(4,'Mary', '123-45-6789')
go
