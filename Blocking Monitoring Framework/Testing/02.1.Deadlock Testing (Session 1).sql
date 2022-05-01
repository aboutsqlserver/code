/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                                 Testing                                  */
/*                       Testing Deadlocks Notification                     */
/*                               (Session 1)                                */
/****************************************************************************/

use tempdb
go

-- Session 1 code
begin tran
	update dbo.Data 
	set  Value = Value + 1
	where ID = 1;

	-- run session 2 code 
	select count(*)
	from dbo.Data with (tablockx)
commit
go



