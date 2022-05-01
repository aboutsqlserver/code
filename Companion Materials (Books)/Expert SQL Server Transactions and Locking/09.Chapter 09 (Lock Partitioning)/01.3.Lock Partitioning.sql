/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 09. Lock Partitioning				        */
/*                 Analyzing Lock Partitioning (Session 3)                  */
/****************************************************************************/

-- You need to have 16 or more schedulers for lock partitioning to be enabled

-- You can artificially change number of cores with undocumented startup flag -P[N] 
-- [N] is number of cores. DO NOT DO THIS IN PRODUCTION!

use SQLServerInternals
go

select scheduler_id 
from sys.dm_exec_requests
where session_id = @@SPID;

-- The request below may or may not be blocked based on the scheduler
-- it executes

select count(*)
from Delivery.Orders;