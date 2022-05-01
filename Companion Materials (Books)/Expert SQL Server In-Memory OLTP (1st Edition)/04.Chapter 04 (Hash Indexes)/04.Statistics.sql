/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 04: Hash Indexes                           */
/*                            04.Statistics                                 */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

dbcc show_statistics
(
	'dbo.HashIndex_HighBucketCount'
	,'PK_HashIndex_HighBucketCount'
)
go

update statistics dbo.HashIndex_HighBucketCount
with fullscan, norecompute; 
go

dbcc show_statistics
(
	'dbo.HashIndex_HighBucketCount'
	,'PK_HashIndex_HighBucketCount'
)
go
