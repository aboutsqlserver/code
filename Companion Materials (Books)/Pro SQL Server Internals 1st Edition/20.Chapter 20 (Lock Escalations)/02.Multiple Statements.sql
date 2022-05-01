/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                     Chapter 20. Lock Escalations				            */
/*                Multiple Statements and Lock Escalations                  */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/

declare
	@I int

select @I = 0

begin tran
	while @I < 65000
	begin
		update Delivery.Orders
		set OrderStatusId = 1
		where OrderId between @I and @I + 4900

		select @I = @I + 4900
	end
	select count(*) as [Lock Count]	
	from sys.dm_tran_locks 
	where request_session_id = @@SPID
rollback
go