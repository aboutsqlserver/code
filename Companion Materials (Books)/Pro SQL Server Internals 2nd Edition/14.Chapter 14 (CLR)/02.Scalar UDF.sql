/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                            Chapter 14. CLR                               */
/*                    Invocation Overhead: Scalar UDF                       */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*   That script uses objects created by "01.Object Creation.sql" script    */
/****************************************************************************/

if object_id(N'dbo.EvenNumber','FN') is not null drop function dbo.EvenNumber;
if object_id(N'dbo.EvenNumberInline','IF') is not null drop function dbo.EvenNumberInline;
go

/*** CLR CODE ***/
/*
[Microsoft.SqlServer.Server.SqlFunction(
	IsDeterministic=true,
	IsPrecise=true,
	DataAccess=DataAccessKind.None
)]
public static SqlInt32 EvenNumberCLR(SqlInt32 num)
{
	return new SqlInt32((num % 2 == 0) ? 1 : 0);
}

[Microsoft.SqlServer.Server.SqlFunction(
	IsDeterministic=true,
	IsPrecise=true,
	DataAccess=DataAccessKind.True
)]
public static SqlInt32 EvenNumberCLRWithDataAccess(SqlInt32 num)
{
	return new SqlInt32((num % 2 == 0) ? 1 : 0);
}
*/

create function dbo.EvenNumber(@Num int)
returns int
with schemabinding
as 
begin
	return (case when @Num % 2 = 0 then 1 else 0 end);
end
go

create function dbo.EvenNumberInline(@Num int)
returns table
as
return
(
	select (case when @Num % 2 = 0 then 1 else 0 end) as Result
)
go

set statistics time on
-- CLR UDF - no data access context
select count(*) 
from dbo.Numbers 
where dbo.EvenNumberCLR(Num) = 1
option (maxdop 1);

-- CLR UDF - data access context
select count(*) 
from dbo.Numbers 
where dbo.EvenNumberCLRWithDataAccess(Num) = 1
option (maxdop 1);

-- TSQL - Scalar UDF
select count(*) 
from dbo.Numbers 
where dbo.EvenNumber(Num) = 1
option (maxdop 1);

-- TSQL - Multi-statement UDF
select count(*) 
from 
	dbo.Numbers n cross apply 
		dbo.EvenNumberInline(n.Num) e
where
	e.Result = 1  
option (maxdop 1);

set statistics time off
go
