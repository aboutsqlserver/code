/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                Chapter 18. Troubleshooting Blocking Issues               */
/*                    Create Blocking Condition (Session 1)                 */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/

set transaction isolation level read uncommitted
begin tran
	delete from Delivery.Orders 
	where OrderId = 97

	-- Run Session 2 code	
	-- Do not Commit/Rollback transaction
rollback
go