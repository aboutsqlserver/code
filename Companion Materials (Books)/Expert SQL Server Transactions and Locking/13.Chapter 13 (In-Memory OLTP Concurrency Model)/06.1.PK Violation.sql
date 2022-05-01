/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. In-Memory OLTP Concurrency Model               */
/*             06.PK Violation (Snapshot Validation) (Session 1)            */
/****************************************************************************/

set nocount on
go

use SQLServerInternalsHK
go

-- STEP 1
begin tran
	insert into dbo.HKData with (snapshot)  
		(ID, Col)
	values(100,100);

  /*** Run Session 2 code ***/
commit
