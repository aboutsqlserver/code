/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 10: Deployment and Management                    */
/*          07.Exploring In-Memory OLTP xEvents and Perf. Counters          */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

select 
	xp.name as [package]
	,xo.name as [event]
	,xo.description as [description]
from 
	sys.dm_xe_packages xp 
		join sys.dm_xe_objects xo on
			xp.guid = xo.package_guid
where
	xp.name like 'XTP%'
order by
	xp.name, xo.name
go

select object_name, counter_name
from sys.dm_os_performance_counters
where object_name like 'XTP%'
order by object_name, counter_name
go
