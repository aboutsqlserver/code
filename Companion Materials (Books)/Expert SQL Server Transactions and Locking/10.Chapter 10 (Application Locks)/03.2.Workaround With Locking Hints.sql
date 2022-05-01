/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 10. Application Locks                       */
/*                 Workaround with Locking Hints (Session 2)                */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

-- Session 2 code
declare
	@EarliestProcessingTime datetime 
select @EarliestProcessingTime = dateadd(minute,-1,getutcdate())

begin tran
	;with DataPacket(ID, Attributes, ProcessingTime)
	as
	(
		select top (50)	ID, Attributes, ProcessingTime
		from dbo.RawData with (updlock, readpast)
		where ProcessingTime <= @EarliestProcessingTime
		order by ID
	)
	update DataPacket
	set ProcessingTime = getutcdate()
	output inserted.ID, inserted.Attributes ;
commit
go
