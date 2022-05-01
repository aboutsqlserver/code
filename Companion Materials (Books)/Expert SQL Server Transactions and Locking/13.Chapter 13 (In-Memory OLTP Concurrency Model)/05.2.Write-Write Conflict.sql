/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. In-Memory OLTP Concurrency Model               */
/*                    05.Write/Write Conflict (Session 2)                   */
/****************************************************************************/

set nocount on
go

use SQLServerInternalsHK
go

/*** Test 1 ***/
begin tran 
	update dbo.HKData with (snapshot)
	set Col = -2 
	where ID = 2
commit
go

/*** Test 2 ***/
begin tran 
	update dbo.HKData with (snapshot)
	set Col = -2 
	where ID = 2
	/*** Run Session 1: Step 2 Code ***/ 
commit
go