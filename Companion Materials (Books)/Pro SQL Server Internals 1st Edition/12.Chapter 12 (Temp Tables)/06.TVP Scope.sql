/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 10. Functions                            */
/*                               TVP Scope                                  */
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
		s.name = 'dbo' and p.name = 'TvpDemo'    
)
	drop proc dbo.TvpDemo
go

if exists
(
	select * 
	from sys.types t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'tvpErrors'    
)
	drop type dbo.tvpErrors
go

create type dbo.tvpErrors as table
(
	RecId int not null,
	[Error]	nvarchar(512) not null,
	primary key(RecId)
)
go

create proc dbo.TvpDemo
(
	@Errors dbo.tvpErrors readonly
)  
as
	select RecId, [Error] from @Errors
	
	exec sp_executesql 
		N'select RecId, [Error] from @Err'
		,N'@Err dbo.tvpErrors readonly'
		,@Err = @Errors
go

declare
	@Errors dbo.tvpErrors

insert into @Errors(RecId, [Error])
values
		(11,'Price mistake'),  
		(42,'Insufficient stock')

exec dbo.TvpDemo @Errors
go
