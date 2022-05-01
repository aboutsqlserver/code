/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                              Initial Setup                               */
/*                       Setting Up Event Notifications                     */
/****************************************************************************/


-- Script does not enable activation on service broker queues. 
-- Set-up security and test framework first

use DBA
go

if exists(select * from sys.services where name = 'BlockedProcessNotificationService') drop service BlockedProcessNotificationService;
if exists(select * from sys.service_queues q join sys.schemas s on q.schema_id = s.schema_id where s.name = 'dbo' and q.name = 'BlockedProcessNotificationQueue') drop queue dbo.BlockedProcessNotificationQueue;
if exists(select * from master.sys.server_event_notifications where name = 'BlockedProcessNotificationEvent') drop event notification BlockedProcessNotificationEvent on server;

if exists(select * from sys.services where name = 'DeadlockNotificationService') drop service DeadlockNotificationService; 
if exists(select * from sys.service_queues q join sys.schemas s on q.schema_id = s.schema_id where s.name = 'dbo' and q.name = 'DeadlockNotificationQueue') drop queue dbo.DeadlockNotificationQueue;
if exists(select * from master.sys.server_event_notifications where name = 'DeadlockNotificationEvent') drop event notification DeadlockNotificationEvent on server;
go

create queue dbo.BlockedProcessNotificationQueue
with status = on;
go

create service BlockedProcessNotificationService
on queue dbo.BlockedProcessNotificationQueue
([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
go

create event notification BlockedProcessNotificationEvent 
on server 
for BLOCKED_PROCESS_REPORT
to service 
	'BlockedProcessNotificationService', 
	'current database' ;
go

create queue dbo.DeadlockNotificationQueue
with status = on;
go

create service DeadlockNotificationService
on queue dbo.DeadlockNotificationQueue
([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
go

create event notification DeadlockNotificationEvent 
on server 
for DEADLOCK_GRAPH
to service 
	'DeadlockNotificationService', 
	'current database' ;
go

/*
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
*/