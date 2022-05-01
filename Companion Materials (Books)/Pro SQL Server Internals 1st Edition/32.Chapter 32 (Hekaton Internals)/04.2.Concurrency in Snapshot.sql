/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                   Chapter 32. In-Memory OLTP Internals                   */
/*                  Concurrency Model: Snapshot (Session 2)                 */
/****************************************************************************/

set noexec off
go

set nocount on
go

use SQLServerInternalsHK
go

if not exists
(
	select * 
	from sys.tables t join sys.schemas s on 
		t.schema_id = s.schema_id 
	where s.name = 'dbo' and t.name = 'HKData'
)
begin
	raiserror('Please create [dbo.HKData] table and run step 1 from session 1 script',16,1) with nowait
	set noexec on
end
go

/*** Test 1 ***/
update dbo.HKData
set Col = -2 
where ID = 2
go

/*** Test 2 ***/
insert into dbo.HKData 
values(10,10)
go
