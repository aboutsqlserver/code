/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 28. System Troubleshooting                     */
/*                           Latch Statistics                               */
/****************************************************************************/


/*** Clearing Waits ***/
-- DBCC SQLPERF('sys.dm_os_latch_stats', CLEAR);

;with Latches
as
(
    select latch_class, wait_time_ms, waiting_requests_count
        ,100. * wait_time_ms / SUM(wait_time_ms) over() as Pct
        ,row_number() over(order by wait_time_ms desc) AS RowNum
    from sys.dm_os_latch_stats with (nolock)
    where latch_class not in (N'BUFFER',N'SLEEP_TASK') and wait_time_ms > 0
)
select
    l1.latch_class as [Latch Type]
    ,l1.waiting_requests_count as [Wait Count]
    ,convert(decimal(12,3), l1.wait_time_ms / 1000.0) as [Wait Time]
    ,convert(decimal(12,1), l1.wait_time_ms / 
        l1.waiting_requests_count) as [Avg Wait Time]
    ,convert(decimal(6,3), l1.Pct) as [Percent]
    ,convert(decimal(6,3), l1.Pct + IsNull(l2.Pct,0)) 
        as [Running Percent]
from
    Latches l1 cross apply
	(
		select sum(l2.Pct) as Pct
		from Latches l2
		where l2.RowNum < l1.RowNum
	) l2
where
	l1.RowNum = 1 or l2.Pct < 99
option (recompile);
go
