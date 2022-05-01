/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                       Chapter 27. Extended Events                        */
/*                         Extended Events Objects                          */
/****************************************************************************/

set noexec off
go


if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 10 
begin
	raiserror('You should have SQL Server 2008+ to execute this script',16,1) with nowait;
	set noexec on
end
go

/*** Packages ***/
select 
	dxp.guid, dxp.name, dxp.description, dxp.capabilities
	,dxp.capabilities_desc, os.name as [Module]
from 
	sys.dm_xe_packages dxp join sys.dm_os_loaded_modules os on	
		dxp.module_address = os.base_address;
go


/*** Events ***/
select 
	xp.name as [Package]
	,xo.name as [Event]
	,xo.Description
from 
	sys.dm_xe_packages xp join sys.dm_xe_objects xo on
		xp.guid = xo.package_guid
where
	(xp.capabilities is null or xp.capabilities & 1 = 0) and
	(xo.capabilities is null or xo.capabilities & 1 = 0) and
	xo.object_type = 'event'
order by
	xp.name, xo.name;
go

/*** Event Columns ***/
select 
	dxoc.column_id
	,dxoc.name
	,dxoc.type_name as [Data Type]
	,dxoc.column_type as [Column Type]
	,dxoc.column_value as [Value]
	,dxoc.description
from 
	sys.dm_xe_object_columns dxoc
where 
	dxoc.object_name = 'sql_statement_completed';
go

/*** Predicates ***/
select 
	xp.name as [Package]
	,xo.name as [Predicate]
	,xo.Description
from 
	sys.dm_xe_packages xp join sys.dm_xe_objects xo on
		xp.guid = xo.package_guid
where
	(xp.capabilities is null or xp.capabilities & 1 = 0) and
	(xo.capabilities is null or xo.capabilities & 1 = 0) and
	xo.object_type = 'pred_source'
order by
	xp.name, xo.name;
go

/*** Comparison Functions ***/
select 
	xp.name as [Package]
	,xo.name as [Comparison Function]
	,xo.Description
from 
	sys.dm_xe_packages xp join sys.dm_xe_objects xo on
		xp.guid = xo.package_guid
where
	(xp.capabilities is null or xp.capabilities & 1 = 0) and
	(xo.capabilities is null or xo.capabilities & 1 = 0) and
	xo.object_type = 'pred_compare'
order by
	xp.name, xo.name;
go

/*** Actions ***/
select 
	xp.name as [Package]
	,xo.name as [Action]
	,xo.Description
from 
	sys.dm_xe_packages xp join sys.dm_xe_objects xo on
		xp.guid = xo.package_guid
where
	(xp.capabilities is null or xp.capabilities & 1 = 0) and
	(xo.capabilities is null or xo.capabilities & 1 = 0) and
	xo.object_type = 'action'
order by
	xp.name, xo.name;
go

/*** Types and Maps ***/
select
	xo.object_type as [Object]
	,xo.name
	,xo.description
	,xo.type_name
	,xo.type_size
from 
	sys.dm_xe_objects xo 
where
	xo.object_type in ('type','map');
go

/*** Map values ***/
select name, map_key, map_value
from sys.dm_xe_map_values
where name = 'wait_types'
order by map_key;
go

/*** Targets ***/
select 
	xp.name as [Package]
	,xo.name as [Action]
	,xo.Description
	,xo.capabilities_desc as [Capabilities]
from 
	sys.dm_xe_packages xp join sys.dm_xe_objects xo on
		xp.guid = xo.package_guid
where
	(xp.capabilities is null or xp.capabilities & 1 = 0) and
	(xo.capabilities is null or xo.capabilities & 1 = 0) and
	xo.object_type = 'target'
order by
	xp.name, xo.name;
go

/*** Target Configuration ***/
select 
	oc.column_id
	,oc.name as [Column]
	,oc.type_name
	,oc.Description
	,oc.capabilities_desc as [Capabilities]
from 
	sys.dm_xe_packages xp join sys.dm_xe_objects xo on
		xp.guid = xo.package_guid
	join sys.dm_xe_object_columns oc on 
		xo.package_guid = oc.object_package_guid and
		xo.name = oc.object_name
where
	(xp.capabilities is null or xp.capabilities & 1 = 0) and
	(xo.capabilities is null or xo.capabilities & 1 = 0) and
	xo.object_type = 'target' and 
	xo.name in ('event_file' /* SQL Server 2012+ */, 'asynchronous_file_target' /* SQL Server 2008/2008R2 */ )
order by
	oc.column_id;
go

