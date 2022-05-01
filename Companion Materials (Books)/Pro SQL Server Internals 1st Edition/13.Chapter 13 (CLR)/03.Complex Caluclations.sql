/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                            Chapter 13. CLR                               */
/*                         Complex Calculations                             */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*   That script uses objects created by "01.Object Creation.sql" script    */
/****************************************************************************/

if object_id(N'dbo.CalcDistance','FN') is not null
	drop function dbo.CalcDistance
go

if object_id(N'dbo.CalcDistanceInline','IF') is not null
	drop function dbo.CalcDistanceInline
go

/*** CLR CODE ***/
/*
[Microsoft.SqlServer.Server.SqlFunction(
	IsDeterministic=true,
	IsPrecise=false,
	DataAccess=DataAccessKind.None
)]
public static SqlDouble CalcDistanceCLR
(
	SqlDouble fromLat, SqlDouble fromLon, 
	SqlDouble toLat, SqlDouble toLon
)
{
	double fromLatR =  Math.PI / 180 * fromLat.Value;
	double fromLonR = Math.PI / 180 * fromLon.Value;
	double toLatR = Math.PI / 180 * toLat.Value;
	double toLonR = Math.PI / 180 * toLon.Value;
   
	return new SqlDouble( 
		2 * Math.Asin(
			Math.Sqrt(
				Math.Pow(Math.Sin((fromLatR - toLatR) / 2.0),2) +
	 			(
					 Math.Cos(fromLatR) * 
					Math.Cos(toLatR) * 
					Math.Pow(Math.Sin((fromLonR - toLonR) / 2.0),2)
				)
			)
		) * 20001600.0 / Math.PI
	);
}
*/

create function dbo.CalcDistance
(
	@FromLat decimal(9,6)
	,@FromLon decimal(9,6)
	,@ToLat decimal(9,6)
	,@ToLon decimal(9,6)
)
returns float
with schemabinding
as 
begin
	declare	
		@Dist float
		,@FromLatR float
		,@FromLonR float
		,@ToLatR float
		,@ToLonR float

	select 
		@FromLatR = radians(@FromLat)
		,@FromLonR = radians(@FromLon)
		,@ToLatR = radians(@ToLat)
		,@ToLonR = radians(@ToLon)

	set @Dist = 
		2 * asin(
			sqrt(
				power(sin( (@FromLatR - @ToLatR) / 2.), 2) + 
	 			(
					cos(@FromLatR) * 
					cos(@ToLatR) * 
					power(sin((@FromLonR - @ToLonR) / 2.0), 2)
				)
			)
		) * 20001600. / pi()
	
	return @Dist
end
go

create function dbo.CalcDistanceInline
(
	@FromLat decimal(9,6)
	,@FromLon decimal(9,6)
	,@ToLat decimal(9,6)
	,@ToLon decimal(9,6)
)
returns table
as
return
(
	with Rads(FromLatR, FromLonR, ToLatR, ToLonR)
	as 
	 (
		select 
			radians(@FromLat), radians(@FromLon),
			radians(@ToLat), radians(@ToLon)
	)
	select	
		2 * asin(
			sqrt(
				power(sin((FromLatR - ToLatR) / 2.), 2) + 
	 			(
					cos(FromLatR) * 
					cos(ToLatR) * 
					power(sin((FromLonR - ToLonR) / 2.0),2)
				)
			)
		) * 20001600. / pi() as Distance
	from Rads
)
go


set statistics time on
-- T-SQL Scalar UDF
select count(*)
from dbo.Numbers
where dbo.CalcDistance(Num % 89, Num % 179, Num % 89 + 1, Num % 179 + 1) > 0
option (maxdop 1)

-- CLR Function
select count(*)
from dbo.Numbers
where dbo.CalcDistanceClr(Num % 89, Num % 179, Num % 89 + 1, Num % 179 + 1) > 0
option (maxdop 1)

-- T-SQL Multi-Statement Function 
select count(*)
from 
	dbo.Numbers n cross apply
		dbo.CalcDistanceInline
			(n.Num % 89, n.Num % 179, n.Num % 89 + 1, n.Num % 179 + 1) d
where	
	d.Distance > 0
option (maxdop 1)

set statistics time off
go