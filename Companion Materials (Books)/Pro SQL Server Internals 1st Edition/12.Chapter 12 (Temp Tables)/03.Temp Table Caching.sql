/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                     Chapter 12. Temporary Tables                         */
/*                       Temporary Tables Caching                           */
/****************************************************************************/

set nocount on
go

/* Run in context of tempdb */
use [tempdb]
go


if exists
(
	select * 
	from sys.procedures p join sys.schemas s on
		p.schema_id = s.schema_id
	where
		s.name = 'dbo' and p.name = 'TempTableCaching'    
)
	drop proc dbo.TempTableCaching
go

create proc dbo.TempTableCaching
as
	create table #T(C int not null primary key)
	drop table #T 
go

/* Check Number of Operations logged */
checkpoint
go

exec dbo.TempTableCaching
go

select Operation, Context, AllocUnitName, [Transaction Name], [Description]
from sys.fn_dblog(null, null)
go

checkpoint
go

exec dbo.TempTableCaching
go

select Operation, Context, AllocUnitName, [Transaction Name], [Description]
from sys.fn_dblog(null, null)
