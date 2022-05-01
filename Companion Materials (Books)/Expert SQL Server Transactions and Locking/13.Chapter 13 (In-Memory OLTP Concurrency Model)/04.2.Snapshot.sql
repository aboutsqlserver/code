/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. In-Memory OLTP Concurrency Model               */
/*                 04.SNAPSHOT Isolation Level (Session 2)                  */
/****************************************************************************/

set nocount on
go

use SQLServerInternalsHK
go

/*** Test 1 ***/
update dbo.HKData
set Col = -20 
where ID = 2
go

/*** Test 2 ***/
insert into dbo.HKData 
values(8,8)
go
