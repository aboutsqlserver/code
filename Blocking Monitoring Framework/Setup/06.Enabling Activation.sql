/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                              Initial Setup                               */
/*                         Enable Queue Activation                          */
/****************************************************************************/

use DBA
go

alter queue dbo.BlockedProcessNotificationQueue
with 
	status = ON,
	retention = OFF,
	activation
	(
		Status = ON,
		Procedure_Name = dbo.SB_BlockedProcessReport_Activation,
		MAX_QUEUE_READERS = 1, 
		EXECUTE AS OWNER
	);
go

alter queue dbo.DeadlockNotificationQueue
with 
	status = ON,
	retention = OFF,
	activation
	(
		Status = ON,
		Procedure_Name = dbo.SB_DeadlockEvent_Activation,
		max_queue_readers = 1, 
		execute as owner
	);
go