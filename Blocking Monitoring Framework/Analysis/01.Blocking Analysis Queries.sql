/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Blocking Analysis Queries                          */
/****************************************************************************/

use DBA
go

-- Find 10 queries that were blocked the most based on plan_hash
with Data
as
( 
	select top 10
		i.BlockedPlanHash
		,count(*) as [Blocking Counts]
		,sum(WaitTime) as [Total Wait Time (ms)]
	from 
		dbo.BlockedProcessesInfo i
	group by
		i.BlockedPlanHash
	order by
		sum(WaitTime) desc
)
select 
	d.*, q.BlockedSql
from 
	Data d
		cross apply
		(
			select top 1 BlockedSql
			from dbo.BlockedProcessesInfo i2
			where i2.BlockedPlanHash = d.BlockedPlanHash
			order by EventDate desc
		) q;
go

-- Find 10 queries that were blocked the most based on query_hash
;with Data
as
( 
	select top 10
		i.BlockedQueryHash
		,count(*) as [Blocking Counts]
		,sum(WaitTime) as [Total Wait Time (ms)]
	from 
		dbo.BlockedProcessesInfo i
	group by
		i.BlockedQueryHash
	order by
		sum(WaitTime) desc
)
select 
	d.*, q.BlockedSql
from 
	Data d
		cross apply
		(
			select top 1 BlockedSql
			from dbo.BlockedProcessesInfo i2
			where i2.BlockedQueryHash = d.BlockedQueryHash
			order by EventDate desc
		) q;
go

-- Get list of objects which suffer from I* waits
;with Objects(DBID,ObjID,WaitTime)
as
(
	select
		ltrim(rtrim(substring(b.Resource,8,o.DBSeparator - 8)))
		,substring(b.Resource, o.DBSeparator + 1, o.ObjectLen)
		,b.WaitTime
	from 
		dbo.BlockedProcessesInfo b
			cross apply
			(
				select 
					charindex(':',Resource,8) as DBSeparator
					,charindex(':',Resource, charindex(':',Resource,8) + 1) - charindex(':',Resource,8) - 1 as ObjectLen
			) o
	where 
		left(b.Resource,6) = 'OBJECT' and 
		left(b.BlockedLockMode,1) = 'I'
)
select 
	db_name(DBID) as [database] 
	,object_name(ObjID, DBID) as [table]
	,count(*) as [# of events]
	,sum(WaitTime) / 1000 as [Wait Time(Sec)]
from Objects
group by 
	db_name(DBID), object_name(ObjID, DBID)
