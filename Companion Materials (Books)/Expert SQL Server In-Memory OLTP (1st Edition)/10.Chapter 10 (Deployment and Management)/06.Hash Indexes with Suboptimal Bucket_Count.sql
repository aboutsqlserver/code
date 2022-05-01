/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 10: Deployment and Management                    */
/*          06.Detecting Hash Indexes with Suboptimal bucket_count          */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

-- You can consider to change predicates based on your workload and use-cases

select 
    s.name + '.' + t.name as [Table]
    ,i.name as [Index]
    ,stat.total_bucket_count as [Total Buckets]
    ,stat.empty_bucket_count as [Empty Buckets]
    ,floor(100. * empty_bucket_count / total_bucket_count)
        as [Empty Bucket %]
    ,stat.avg_chain_length as [Avg Chain]
    ,stat.max_chain_length as [Max Chain]
from
    sys.dm_db_xtp_hash_index_stats stat
        join sys.tables t on
            stat.object_id = t.object_id
        join sys.indexes i on
            stat.object_id = i.object_id and
            stat.index_id = i.index_id
        join sys.schemas s on 
            t.schema_id = s.schema_id
where
    stat.avg_chain_length > 3 or
	stat.max_chain_length > 50 or
	floor(100. * empty_bucket_count / total_bucket_count) > 50
go