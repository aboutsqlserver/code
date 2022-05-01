/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. In-Memory OLTP Concurrency Model               */
/*            06.PK Violation (Snapshot Validation) (Session 2)             */
/****************************************************************************/

set nocount on
go

use SQLServerInternalsHK
go

begin tran
	insert into dbo.HKData with (snapshot)  
		(ID, Col)
	values(100,100);

	/*** Commit Tran in Session 1 ***/
commit
