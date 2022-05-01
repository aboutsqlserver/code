/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 10: Deployment and Management                    */
/*                         01.Resource Governor                             */
/****************************************************************************/

set nocount on
go

use master
go

if not exists
(
	select * from sys.resource_governor_resource_pools where name = 'InMemoryDataPool'
)
begin
	create resource pool InMemoryDataPool
	with
	(
		min_memory_percent=40
		,max_memory_percent=40
	);

	alter resource governor reconfigure;
end
go

-- Binding the database. You need to take DB offline and 
-- bring it back offline for the changes to make effects

exec sys.sp_xtp_bind_db_resource_pool
	@database_name = 'InMemoryOLTP2014'
	,@pool_name = 'InMemoryDataPool';

alter database InMemoryOLTP2014 set offline;
alter database InMemoryOLTP2014 set online;
go

-- Remove binding. You need to take DB offline and 
-- bring it back offline for the changes to make effects

exec sys.sp_xtp_unbind_db_resource_pool
	@database_name = 'InMemoryOLTP2014';

alter database InMemoryOLTP2014 set offline;
alter database InMemoryOLTP2014 set online;
go
