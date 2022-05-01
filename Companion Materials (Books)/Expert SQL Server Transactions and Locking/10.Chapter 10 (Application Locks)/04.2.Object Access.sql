/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 10. Application Locks                       */
/*                  Preventing Access to the Object (Session 2)             */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go

-- Index Rebuild
begin tran
	exec sp_getapplock
		@Resource = 'TenantDataAccess'
		,@LockMode = 'Exclusive' 
		,@LockOwner = 'Transaction'
		,@LockTimeout = -1 ; -- Indefinite wait

	alter index IDX_CollectedData_TenantId_OnDate_Id
	on dbo.CollectedData rebuild;
commit