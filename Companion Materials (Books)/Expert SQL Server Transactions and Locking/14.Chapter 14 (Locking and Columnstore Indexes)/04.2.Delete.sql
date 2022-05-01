/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 14. Locking and Columnstore Indexes                */
/*                      Delete Workload (Session 2)                         */
/****************************************************************************/

use SQLServerInternals
go

-- Test 3: Locking during deletes
delete from dbo.Test
where ID=50;