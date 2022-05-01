/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 06: Memory Consumers and Off-Row Storage            */
/*                  03. Performance Impact of Off-Row Storage               */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

set statistics time on

select count(*)
from dbo.HashIndex_LowBucketCount 
    with (index = PK_HashIndex_LowBucketCount);

select count(*)
from dbo.HashIndex_LowBucketCount 