/****************************************************************************/
/*         SQL Server Advanced Troubleshooting and Performance Tuning       */
/*         O'Reilly, 2022. ISBN-13: 978-1098101923 ISBN-10: 1098101928      */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      https://aboutsqlserver.com                          */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 08: Locking, Blocking and Concurrency               */
/*                         Deadlocks (Session 2)                            */
/****************************************************************************/

USE SQLServerInternals
GO

-- Emulating deadlock
-- Step 1: 
BEGIN TRAN
	UPDATE dbo.Orders
	SET OrderStatus = 1
	WHERE OrderId = 250;

	SELECT COUNT(*) AS [Cnt]
	FROM dbo.Orders WITH (READCOMMITTEDLOCK)
	WHERE CustomerId = 18;
COMMIT