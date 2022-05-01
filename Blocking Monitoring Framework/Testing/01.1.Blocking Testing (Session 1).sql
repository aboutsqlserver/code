/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                                 Testing                                  */
/*                    Testing Blocking Event Notification                   */
/*                               (Session 1)                                */
/****************************************************************************/

use tempdb
go

-- Emulate blocking
-- Session 1 code
begin tran
	update dbo.Data with (tablockx)
	set  Value = Value + 1
	where ID = 2;

	-- run session 2 code below and wait for some time
commit
go



