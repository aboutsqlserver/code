/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 19. Deadlocks				            */
/*                      Key Lookup Deadlock (Session 2)                     */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
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