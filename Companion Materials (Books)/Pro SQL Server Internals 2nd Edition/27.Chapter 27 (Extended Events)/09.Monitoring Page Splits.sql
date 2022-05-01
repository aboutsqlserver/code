/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 27. Extended Events                        */
/*                          Monitoring Page Splits                          */
/****************************************************************************/

set noexec off
go


if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 11 -- SQL Server 2012/2014 is required
begin
	raiserror('You should have SQL Server 2012+ to execute this script',16,1) with nowait;
	raiserror('SQL Server 2008/2008R2 does not support required events',16,1) with nowait;
	set noexec on
end
go

if exists(select * from sys.server_event_sessions where name = 'PageSplits_Tracking') drop event session PageSplits_Tracking on server;
go

create event session PageSplits_Tracking
on server
add event sqlserver.transaction_log
(
    where operation = 11		-- lop_delete_split 
        and database_id = 17	-- Database ID
)
add target package0.histogram
(
    set 
        filtering_event_name = 'sqlserver.transaction_log',
        source_type = 0, -- event column
        source = 'alloc_unit_id'
);
go

alter event session PageSplits_Tracking
on server
state=start;
go

-- You can aggrefate data by different attributes, for example
-- on  per-table basis if needed.
;with Data(alloc_unit_id, splits)
as
(
    select c.n.value('(value)[1]', 'bigint') as alloc_unit_id, c.n.value('(@count)[1]', 'bigint') as splits
    from 
    (
        select convert(xml,target_data) target_data
        from sys.dm_xe_sessions s with (nolock) join sys.dm_xe_session_targets t on
            s.address = t.event_session_address
        where s.name = 'PageSplits_Tracking' and t.target_name = 'histogram' 
    ) as d cross apply 
        target_data.nodes('HistogramTarget/Slot') as c(n)
)
select
    s.name + '.' + o.name as [Table], i.index_id, i.name as [Index]
    ,d.Splits, i.fill_factor as [Fill Factor]
from 
    Data d join sys.allocation_units au with (nolock) on
        d.alloc_unit_id = au.allocation_unit_id
    join sys.partitions p with (nolock) on
        au.container_id = p.partition_id
    join sys.indexes i with (nolock) on 
        p.object_id = i.object_id and p.index_id = i.index_id
    join sys.objects o with (nolock) on
        i.object_id = o.object_id
    join sys.schemas s on
        o.schema_id = s.schema_id;
go

-- Clean-up
alter event session PageSplits_Tracking
on server
state=stop;
go

drop event session PageSplits_Tracking on server;
go