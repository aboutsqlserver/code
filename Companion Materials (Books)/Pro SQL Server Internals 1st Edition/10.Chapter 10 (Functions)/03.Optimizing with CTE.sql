/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 10. Functions                            */
/*                 Optimizing Multi-statement UDF with CTE                  */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************
That script shows an example of calculating bounding box for a circle, defined 
by latitude and longitude of the center point and radius. The task and algorithm
is described at: 
http://aboutsqlserver.com/2013/09/03/optimizing-sql-server-spatial-queries-with-bounding-box/

This is just an example of what can be done in terms of optimization. 
CLR function is the better choice in this particluar use-case comparing to 
inline table-values function
****************************************************************************/

if object_id(N'dbo.GetCornerPoints','TF') is not null
	drop function dbo.GetCornerPoints
go

if object_id(N'dbo.GetCornerPointsInline','IF') is not null
	drop function dbo.GetCornerPointsInline
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Positions'    
)
	drop table dbo.Positions
go

create table dbo.Positions
(
	ID int not null identity(1,1),
	Lat float not null,
	Lon float not null,
	A1 float,
	A2 float,
	B1 float,
	B2 float, 

	constraint PK_Positions
	primary key clustered(ID)
)
go

;with Latitudes(Lat)
as
(
	select convert(float,25.0)
	
	union all
	
	select convert(float,Lat + 0.1)
	from Latitudes
	where Lat < convert(float,48.0)
)
,Longitudes(Lon)
as
(
	select convert(float,-75.0)
	
	union all
	
	select Lon - 0.1
	from Longitudes
	where Lon > -123
)
insert into dbo.Positions(Lat, Lon)
	select Latitudes.Lat, Longitudes.Lon
	from Latitudes cross join Longitudes
option (maxrecursion 0)
go


/*** Multi-statement implementation ***/
create function dbo.GetCornerPoints(@Distance float, @Lat float, @Lon float)
returns @Result table
(
	A1 float,
	A2 float,
	B1 float,
	B2 float
)
as
begin
	declare
		@Tmp float, @A1 float, @A2 float, @B1 float, @B2 float, @AVar float
		,@BVar float, @CAngle float, @APlusB float, @AMinusB float, @BAngle float

	select @A1 = @Lat - @Distance / 60.0 * 5280.0 / 6076.11549
	if @A1 > 90.
		select @A1 = @A1 - 90.
	else if @A1 < -90.
		select @A1 = 180. - @A1
	
	select @A2 = 2 * @Lat - @A1
	
	if @A1 > @A2
	begin
		select @Tmp = @A1
		select @A1 = @A2
		select @A2 = @Tmp
	end
	
	select 
		@AVar = (90 - @Lat) * PI() / 180.
		,@BVar = (@Distance / 69.1) * PI() / 180.
		,@CAngle = PI() / 4.0
	
	select 
		@APlusB = 2 * ATan(Cos((@AVar - @BVar) / 2.) / (Cos((@AVar + @BVar) / 2.) * Tan(@CAngle)))
		,@AMinusB = 2 * ATan(Sin((@AVar - @BVar) / 2.) / (Sin((@AVar + @BVar) / 2) * Tan(@CAngle)))
	
	select
		@BAngle = (@APlusB - @AMinusB) / 2.0
	
	select 
		@B1 = @Lon + @BAngle * 180. / PI()

    if @B1 > 180. 
      select @B1 = @B1 - 360.
    else if @B1 < -180. 
      select @B1 = @B1 + 360.

	select @B2 = 2.0 * @Lon - @B1
	
	if @B1 > @B2
	begin
		select @Tmp = @B1
		select @B1 = @B2
		select @B2 = @Tmp
	end
	
	insert into @Result(A1, A2, B1, B2) values(@A1, @A2, @B1, @B2)
	return
end
go

/*** Inline implementation ***/	
create function dbo.GetCornerPointsInline(@Distance float, @Lat float, @Lon float)
returns table
as return
(
	with ALatCore(A)
	as
	(
		select @Lat - @Distance / 60.0 * 5280.0 / 6076.11549
	)
	, A1Core(A1)
	as
	(
		select 
			case 
				when A > 90.0 
				then A - 90.0
				else 
					case 
						when A < -90.0
						then -A - 180.0
						else A
					end
			end
		from ALatCore
	)
	,A1A2(A1, A2)
	as
	(
		select A1, 2.0 * @lat - A1
		from A1Core
	)
	,Consts(AVar, BVar, CAngle)
	as
	(
		select radians(90.0 - @Lat), radians(@Distance / 69.1), TAN(PI() / 4.0)
	)
	,ALonCore(B)
	as
	(
		select @Lon + 
			(
				(2.0 * ATan(Cos((AVar - BVar) / 2.0) / (Cos((AVar + BVar) / 2.0) * CAngle))) - 
				(2.0 * ATan(Sin((AVar - BVar) / 2.0) / (Sin((AVar + BVar) / 2.0) * CAngle)))
			) * 90.0 / PI()
		from Consts
	)
	,B1Core(B1)
	as
	(
		select 
			case 
				when B > 180.0
				then B - 360.0
				else 
					case 
						when B < -180.0
						then B + 360.0
						else B
					end
			end
		from ALonCore
	)	
	,B1B2(B1, B2)
	as
	(
		select B1, 2.0 * @Lon - B1
		from B1Core
	)
	select 
		(
			case 
				when A1 > A2 
				then A2 
				else A1 
			end 
		) as A1,
		(
			case 
				when A1 > A2 
				then A1 
				else A2 
			end
		) as A2,
		(
			case 
				when B1 > B2 
				then B2 
				else B1 
			end
		) as B1,
		(
			case 
				when B1 > B2 
				then B1 
				else B2 
			end
		) as B2
	from A1A2 cross join B1B2
)
go

set statistics time on
	
update dbo.Positions	
set
	dbo.Positions.A1 = p.A1
	,dbo.Positions.A2 = p.A2
	,dbo.Positions.B1 = p.B1
	,dbo.Positions.B2 = p.B2	
from
	dbo.Positions cross apply 
		dbo.GetCornerPoints(
			250,
			dbo.Positions.Lat,
			dbo.Positions.Lon) p	
	
	
update dbo.Positions	
set
	dbo.Positions.A1 = p.A1
	,dbo.Positions.A2 = p.A2
	,dbo.Positions.B1 = p.B1
	,dbo.Positions.B2 = p.B2	
from
	dbo.Positions cross apply 
		dbo.GetCornerPointsInline(
			250,
			dbo.Positions.Lat,
			dbo.Positions.Lon) p	

set statistics time off
go


