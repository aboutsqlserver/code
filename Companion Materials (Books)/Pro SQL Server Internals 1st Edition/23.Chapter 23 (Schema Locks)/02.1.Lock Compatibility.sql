/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                       Chapter 23. Schema Locks				            */
/*                    Lock Compatibility (Session 1)                        */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/

-- STEP 1: 
begin tran
	select *
	from Delivery.Orders 
		with (repeatableread)
	where OrderId = 1
		  
	-- Run Sessions 2 and 3 code

	-- STEP 2:
	select
		l.request_session_id as [SPID]
		,l.resource_description
		,l.resource_type
		,l.request_mode
		,l.request_status													
		,r.blocking_session_id							,''
	from 
		sys.dm_tran_locks l join
			sys.dm_exec_requests r on
			l.request_session_id =
				r.session_id      
	where	
		resource_type = 'KEY'
rollback
go

