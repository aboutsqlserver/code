/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                      Chapter 22. Application Locks                       */
/*                      Application Locks (Session 2)                       */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

if not exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'RawData'    
)
begin
	raiserror('Please create [RawData] table with "01.Table Creation.sql" script',16,1) with nowait
	set noexec on
end
go

-- Session 2 code
exec dbo.LoadRawData @PacketSize = 50
go
