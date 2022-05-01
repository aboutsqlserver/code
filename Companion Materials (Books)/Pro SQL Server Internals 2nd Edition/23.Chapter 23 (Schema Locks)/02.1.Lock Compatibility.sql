/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 23. Schema Locks				            */
/*                    Lock Compatibility (Session 1)                        */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

-- STEP 1: 
begin tran
	select *
	from Delivery.Orders 
		with (repeatableread)
	where OrderId = 1;
		  
	-- Run Sessions 2 and 3 code

	-- STEP 2:
	select
		l.request_session_id as [SPID]
		,l.resource_description
		,l.resource_type
		,l.request_mode
		,l.request_status													
		,r.blocking_session_id
	from 
		sys.dm_tran_locks l join
			sys.dm_exec_requests r on
			l.request_session_id =
				r.session_id      
	where	
		resource_type = 'KEY';
rollback
go

