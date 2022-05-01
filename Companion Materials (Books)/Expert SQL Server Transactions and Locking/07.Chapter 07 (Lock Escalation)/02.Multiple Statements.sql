/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 07. Lock Escalation				            */
/*                Multiple Statements and Lock Escalations                  */
/****************************************************************************/

use SQLServerInternals
go

declare
	@I int

select @I = 0;

begin tran
	while @I < 65000
	begin
		update Delivery.Orders
		set OrderStatusId = 1
		where OrderId between @I and @I + 4900;

		select @I = @I + 4500;
	end

	select count(*) as [Lock Count]	
	from sys.dm_tran_locks 
	where request_session_id = @@SPID;
rollback
go