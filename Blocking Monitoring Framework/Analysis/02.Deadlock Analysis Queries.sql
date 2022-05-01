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
		i.PlanHash
		,count(*) as [Blocking Counts]
		,sum(WaitTime) as [Total Wait Time (ms)]
	from 
		dbo.DeadlockProcesses i
	group by
		i.PlanHash
	order by
		sum(WaitTime) desc
)
select 
	d.*, q.Sql
from 
	Data d
		cross apply
		(
			select top 1 Sql
			from dbo.DeadlockProcesses i2
			where i2.PlanHash = d.PlanHash
			order by EventDate desc
		) q;
go

-- Find 10 queries that were blocked the most based on query_hash
;with Data
as
( 
	select top 10
		i.QueryHash
		,count(*) as [Blocking Counts]
		,sum(WaitTime) as [Total Wait Time (ms)]
	from 
		dbo.DeadlockProcesses i
	group by
		i.QueryHash
	order by
		sum(WaitTime) desc
)
select 
	d.*, q.Sql
from 
	Data d
		cross apply
		(
			select top 1 Sql
			from dbo.DeadlockProcesses i2
			where i2.QueryHash = d.QueryHash
			order by EventDate desc
		) q;
go

