/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                     Chapter 12. Temporary Tables                         */
/*                 Temporary Tables: Scope and Lifetime                     */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go


if exists
(
	select * 
	from sys.procedures p join sys.schemas s on
		p.schema_id = s.schema_id
	where
		s.name = 'dbo' and p.name = 'P1'    
)
	drop proc dbo.P1
go

if exists
(
	select * 
	from sys.procedures p join sys.schemas s on
		p.schema_id = s.schema_id
	where
		s.name = 'dbo' and p.name = 'P2'    
)
	drop proc dbo.P
go

create table #SessionScope(C1 int not null)
go

create proc dbo.P1
as
begin
	-- Success: #SessionScope is visible because it's created 
	-- in the session scope
	select * from #SessionScope
	
	-- Results depends on how P1 is called
	select * from #P2Scope
end
go

create proc dbo.P2
as
begin
	create table #P2Scope(ID int)
	
	-- Success: #SessionScope is visible because it's created 
	-- in the session scope
	select * from #SessionScope

	-- Success - P1 is called from P2 so table #P2Scope is visible there
	exec dbo.P1
	
	-- Success #P2Scope is visible from dynamic SQL called from within P2
	exec sp_executesql N'select * from #P2Scope'
end
go

-- Success: #SessionScope is visible because it's created in the session scope
select * from #SessionScope

-- Success 
exec dbo.P2

-- Error: Invalid object name '#P2Scope'
exec dbo.P1
