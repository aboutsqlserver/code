/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                  Chapter 35. In-Memory OLTP Internals                    */
/*                  Memory-Optimized Tables Memory Usage                    */
/****************************************************************************/

set noexec off
go

if convert(int,
		left(
			convert(nvarchar(128), serverproperty('ProductVersion')),
			charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
		)
) < 12 
begin
	raiserror('You should have SQL Server 2014-2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3 or charindex('X64',@@Version) = 0
begin
	raiserror('That script requires 64-Bit Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

use SQLServerInternalsHK
go

select object_name(object_id) as [Object Name], *
from sys.dm_db_xtp_table_memory_stats;
