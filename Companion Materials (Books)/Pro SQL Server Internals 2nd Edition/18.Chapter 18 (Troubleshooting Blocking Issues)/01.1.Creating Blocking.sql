/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                Chapter 18. Troubleshooting Blocking Issues               */
/*                    Create Blocking Condition (Session 1)                 */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

set transaction isolation level read uncommitted
begin tran
	delete from Delivery.Orders 
	where OrderId = 97;

	-- Run Session 2 code	
	-- Do not Commit/Rollback transaction
rollback
go