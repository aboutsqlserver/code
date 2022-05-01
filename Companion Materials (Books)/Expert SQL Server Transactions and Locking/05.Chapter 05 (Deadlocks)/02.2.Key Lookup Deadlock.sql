/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 05. Deadlocks				            */
/*                      Key Lookup Deadlock (Session 2)                     */
/****************************************************************************/

set nocount on
go

use SQLServerInternals
go

-- Session 2 code (Run in parallel with Session 1 code)
declare
	@Col int

while 1 = 1
begin
	select @Col = Col1 
	from dbo.Data
	where NCIKey = 10;
end
go