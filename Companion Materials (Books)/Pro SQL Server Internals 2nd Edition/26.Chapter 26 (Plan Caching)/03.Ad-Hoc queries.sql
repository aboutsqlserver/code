/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 26. Plan Caching                         */
/*                      Ad-Hoc Queries and Plan Cache                       */
/****************************************************************************/


use [SqlServerInternals]
go

/****************************************************************************/
/*        This script clear plan cache and changes server settings.         */
/*                  Do not run it on production server                      */
/****************************************************************************/

exec sys.sp_configure N'optimize for ad hoc workloads', 0;
go
reconfigure with override;
go

dbcc freeproccache
go

declare 
	@SQL nvarchar(max)
	,@I int = 0

while @I < 1000
begin
	select @SQL = 
		N'declare @C int;select @C=ID from dbo.Employees where ID=' 
			+ CONVERT(nvarchar(10),@I);
	exec(@SQL);
	select @I += 1;
end	
go

select 
	p.usecounts, p.cacheobjtype, p.objtype, p.size_in_bytes,
	t.[text] 
from 
	sys.dm_exec_cached_plans p
		cross apply sys.dm_exec_sql_text(p.plan_handle) t
where 
	p.cacheobjtype like 'Compiled Plan%' and 
	t.[text] like '%Employees%'
order by
	p.objtype desc
option (recompile);
go

exec sys.sp_configure N'optimize for ad hoc workloads', 1;
go
reconfigure with override;
go

dbcc freeproccache
go

declare 
	@SQL nvarchar(max)
	,@I int = 0

while @I < 1000
begin
	select @SQL = 
		N'declare @C int;select @C=ID from dbo.Employees where ID=' 
			+ CONVERT(nvarchar(10),@I);
	exec(@SQL);
	select @I += 1;
end	
go

select 
	p.usecounts, p.cacheobjtype, p.objtype, p.size_in_bytes,
	t.[text] 
from 
	sys.dm_exec_cached_plans p
		cross apply sys.dm_exec_sql_text(p.plan_handle) t
where 
	p.cacheobjtype like 'Compiled Plan%' and 
	t.[text] like '%Employees%'
order by
	p.objtype desc
option (recompile);
go
