/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                        Chapter 29. Query Store                           */
/*                Emulating Parameter Sniffing (Session 2)                  */
/****************************************************************************/

set noexec off
go

if convert(int,
		left(
			convert(nvarchar(128), serverproperty('ProductVersion')),
			charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
		)
	) < 13
begin
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait
	set noexec on
end
go

use SQLServerInternals
go

if not exists
(
	select * 
	from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id 
	where s.name = 'dbo' and p.name = 'GetAverageSalary'
) 

begin
	raiserror('Please create the objects and run dbo.GetAverageSalary SP from "02.1.Emulating Parameter Sniffing.sql" script',16,1) with nowait
	set noexec on
end
go

-- Clearing procedure plan cache for the database
alter database scoped configuration clear procedure_cache;
go

exec dbo.GetAverageSalary @Country='CANADA';
go
