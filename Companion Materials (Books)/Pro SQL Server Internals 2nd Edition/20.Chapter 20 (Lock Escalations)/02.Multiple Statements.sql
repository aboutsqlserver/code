/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 20. Lock Escalations				            */
/*                Multiple Statements and Lock Escalations                  */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

declare
	@I int

select @I = 0;

begin tran
	while @I < 65000
	begin
		update Delivery.Orders
		set OrderStatusId = 1
		where OrderId between @I and @I + 4900;

		select @I = @I + 4900;
	end

	select count(*) as [Lock Count]	
	from sys.dm_tran_locks 
	where request_session_id = @@SPID;
rollback
go