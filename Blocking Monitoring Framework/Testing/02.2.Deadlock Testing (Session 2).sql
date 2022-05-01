/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                                 Testing                                  */
/*                       Testing Deadlocks Notification                     */
/*                               (Session 2)                                */
/****************************************************************************/

use tempdb
go

-- Session 2 code
begin tran
	update dbo.Data 
	set  Value = Value + 1
	where ID = 4;

	select count(*)
	from dbo.Data with (tablock)
commit
go



