/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 04.Blocking In The System                    */
/*                    Create Blocking Condition (Session 1)                 */
/****************************************************************************/

use SQLServerInternals
go


set transaction isolation level read uncommitted
begin tran
	delete from Delivery.Orders 
	where OrderId = 95;

	-- Run Session 2 code	
	-- Do not Commit/Rollback transaction
rollback
go