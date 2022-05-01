/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 08: Locking, Blocking and Concurrency               */
/*                       Lock Escalation (Session 2)                        */
/****************************************************************************/

USE SQLServerInternals
GO

BEGIN TRAN
	INSERT INTO dbo.Orders(OrderId,OrderNum,OrderDate,CustomerId,Amount,OrderStatus)
	VALUES(100000,'100000',GETDATE(),1,100,0);
ROLLBACK