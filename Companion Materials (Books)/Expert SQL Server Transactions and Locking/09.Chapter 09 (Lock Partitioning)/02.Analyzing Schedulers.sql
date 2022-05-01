/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 09. Lock Partitioning				        */
/*                    Analyzing Session Scheduler Change                    */
/****************************************************************************/

-- This script shows the possibility for the session to change a scheduler
-- within an active transaction. It does not happen very often but it may happen
-- You can increase the chance of the occurence during the demo by running it on 
-- the very busy server with large (>16) numbers of cores/schedulers
-- 
-- You can artificially change number of cores -with undocumented startup flag -P[N] 
-- [N] is number of cores. DO NOT USE THIS IN PRODUCTION

begin tran
go
	-- Run select below multiple times giving it 5-10 seconds in between the executions
	-- It may take a while for scheduler to change
	select scheduler_id 
	from sys.dm_exec_requests
	where session_id = @@SPID
	option (recompile);
go

rollback 
go

		
