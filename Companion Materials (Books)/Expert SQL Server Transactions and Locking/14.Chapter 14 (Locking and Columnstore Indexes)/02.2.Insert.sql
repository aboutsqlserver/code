/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 14. Locking and Columnstore Indexes                */
/*                      Append Workload (Session 2)                         */
/****************************************************************************/

use SQLServerInternals
go

insert into dbo.Test(ID, Col)
values(-2,-2);