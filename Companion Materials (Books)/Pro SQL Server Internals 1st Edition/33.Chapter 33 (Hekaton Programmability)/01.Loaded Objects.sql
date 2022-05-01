/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                 Chapter 33. In-Memory OLTP Programmability               */
/*                Natively-Compiled Objects Loaded Into Memory              */
/****************************************************************************/

set noexec off
go

set nocount on
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 12 
begin
	raiserror('You should have SQL Server 2014 to execute this script',16,1) with nowait
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3 or charindex('X64',@@Version) = 0
begin
	raiserror('That script requires 64-Bit Enterprise Edition of SQL Server to run',16,1)
	set noexec on
end
go

select 
	s.name + '.' + o.name as [Object Name]
	,o.object_id
from
	(
		select schema_id, name, object_id
		from sys.tables 
		where is_memory_optimized = 1
		union all
		select schema_id, name, object_id
		from sys.procedures
	) o join sys.schemas s on
		o.schema_id = s.schema_id;

select * 
from sys.dm_os_loaded_modules 
where description = 'XTP Native DLL';
go

