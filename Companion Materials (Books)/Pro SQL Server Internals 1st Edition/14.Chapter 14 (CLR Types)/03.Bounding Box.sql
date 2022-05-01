/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 14. CLR Types                            */
/*             Optimizing Geospatial Queries with Bounding Box              */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*   That script uses objects created by "01.Object Creation.sql" script    */
/*     from "13.Chapter 13 (CLR)" Chapter and "03.Spatital.sql" script      */
/****************************************************************************/

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'LocationsGeo2' and s.name = 'dbo'
)
	drop table dbo.LocationsGeo2
go

/*** CLR CODE ***/
/*
private struct BoundingBox 
{
	public double minLat;
	public double maxLat;
	public double minLon;
	public double maxLon;
}

private static void CircleBoundingBox_FillValues(
	object obj, out SqlDouble MinLat, out SqlDouble MaxLat, 
	out SqlDouble MinLon, out SqlDouble MaxLon)
{
	BoundingBox box = (BoundingBox)obj;
	MinLat = new SqlDouble(box.minLat);
	MaxLat = new SqlDouble(box.maxLat);
	MinLon = new SqlDouble(box.minLon);
	MaxLon = new SqlDouble(box.maxLon);
}

[Microsoft.SqlServer.Server.SqlFunction(
	DataAccess = DataAccessKind.None,
	IsDeterministic = true, IsPrecise = false,
	SystemDataAccess = SystemDataAccessKind.None,
	FillRowMethodName = "CircleBoundingBox_FillValues", 
	TableDefinition = "MinLat float, MaxLat float, MinLon float, MaxLon float"
)]
public static IEnumerable CalcCircleBoundingBox(SqlDouble lat, SqlDouble lon, SqlInt32 distance)
{
 	if (lat.IsNull || lon.IsNull || distance.IsNull)
		return null;

	BoundingBox[] box = new BoundingBox[1];

	double latR =  Math.PI / 180 * lat.Value;
	double lonR = Math.PI / 180 * lon.Value;
	double rad45 = 0.785398163397448300;  // RADIANS(45.)
	double rad135 = 2.356194490192344800; // RADIANS(135.)
	double rad225 = 3.926990816987241400; // RADIANS(225.)
	double rad315 = 5.497787143782137900; // RADIANS(315.) 
	double distR = distance.Value * 1.4142135623731 * Math.PI / 20001600.0;

	double latR45 = Math.Asin(Math.Sin(latR) * Math.Cos(distR) + Math.Cos(latR) * Math.Sin(distR) * Math.Cos(rad45));
	double latR135 = Math.Asin(Math.Sin(latR) * Math.Cos(distR) + Math.Cos(latR) * Math.Sin(distR) * Math.Cos(rad135));
	double latR225 = Math.Asin(Math.Sin(latR) * Math.Cos(distR) + Math.Cos(latR) * Math.Sin(distR) * Math.Cos(rad225));
	double latR315 = Math.Asin(Math.Sin(latR) * Math.Cos(distR) + Math.Cos(latR) * Math.Sin(distR) * Math.Cos(rad315));

	double dLonR45 = Math.Atan2(Math.Sin(rad45) * Math.Sin(distR) * Math.Cos(latR), 
		Math.Cos(distR) - Math.Sin(latR) * Math.Sin(latR45));
	double dLonR135 = Math.Atan2(Math.Sin(rad135) * Math.Sin(distR) * Math.Cos(latR), 
		Math.Cos(distR) - Math.Sin(latR) * Math.Sin(latR135));
	double dLonR225 = Math.Atan2(Math.Sin(rad225) * Math.Sin(distR) * Math.Cos(latR), 
		Math.Cos(distR) - Math.Sin(latR) * Math.Sin(latR225));
	double dLonR315 = Math.Atan2(Math.Sin(rad315) * Math.Sin(distR) * Math.Cos(latR), 
		Math.Cos(distR) - Math.Sin(latR) * Math.Sin(latR315));

	double lat45 = latR45 * 180.0 / Math.PI;
	double lat225 = latR225 * 180.0 / Math.PI;
	double lon45 = (((lonR - dLonR45 + Math.PI) % (2 * Math.PI)) - Math.PI) * 180.0 / Math.PI;
	double lon135 = (((lonR - dLonR135 + Math.PI) % (2 * Math.PI)) - Math.PI) *180.0 / Math.PI;
	double lon225 = (((lonR - dLonR225 + Math.PI) % (2 * Math.PI)) - Math.PI) *180.0 / Math.PI;
	double lon315 = (((lonR - dLonR315 + Math.PI) % (2 * Math.PI)) - Math.PI) *180.0 / Math.PI;

	box[0].minLat = Math.Min(lat45, lat225);
	box[0].maxLat = Math.Max(lat45, lat225);
	box[0].minLon = Math.Min(Math.Min(lon45, lon135), Math.Min(lon225,lon315));
	box[0].maxLon = Math.Max(Math.Max(lon45, lon135), Math.Max(lon225, lon315));
	return box;
}
*/


create table dbo.LocationsGeo2
(
	CompanyId int not null,
	Id int not null identity(1,1),
	Location geography not null,

	constraint PK_LocationsGeo2
	primary key clustered(CompanyId,Id)
);

-- 1,600,000 rows; 40 companies; 40,000 rows per company
;with Companies(CID)
as
(
	select 1
	union all 
	select CID + 1 from Companies where CID < 40
)
,Locations(Location)
as
(
	select top 40000 Location
	from dbo.LocationsGeo
)
insert into dbo.LocationsGeo2(CompanyId,Location)
	select c.CID, l.Location
	from Locations l cross join Companies c;
go

create spatial index Idx_LocationsGeo2_Spatial
on dbo.LocationsGeo2(Location);
go

-- Enable "Include Actual Execution Plan"
/*** Test Queries ***/
declare
	@Lat decimal(9,6) = 47.620309
	,@Lon decimal(9,6) = -122.349563
	,@CompanyId int = 15

declare
	@g geography = geography::Point(@Lat,@Lon,4326)
	
select count(*)
from dbo.LocationsGeo2 
where Location.STDistance(@g) < 1609 and CompanyId = @CompanyId
	
select count(*)
from dbo.LocationsGeo2 with (index=Idx_LocationsGeo2_Spatial)
where Location.STDistance(@g) < 1609 and CompanyId = @CompanyId
go




/*** Implementing Bounding Box ***/
alter table dbo.LocationsGeo2 add MinLat decimal(9,6);
alter table dbo.LocationsGeo2 add MaxLat decimal(9,6);
alter table dbo.LocationsGeo2 add MinLon decimal(9,6);
alter table dbo.LocationsGeo2 add MaxLon decimal(9,6);
go

update t
set
	t.MinLat = b.MinLat
	,t.MinLon = b.MinLon
	,t.MaxLat = b.MaxLat
	,t.MaxLon = b.MaxLon
from
	dbo.LocationsGeo2 t cross apply
		dbo.CalcCircleBoundingBox(t.Location.Lat,t.Location.Long,1609) b;
go

create index IDX_LocationsGeo2_BoundingBox
on dbo.LocationsGeo2(CompanyId, MinLon, MaxLon)
include (MinLat, MaxLat);
go



/*** Test Query ***/
declare
	@Lat decimal(9,6) = 47.620309
	,@Lon decimal(9,6) = -122.349563
	,@CompanyId int = 15

declare
	@g geography = geography::Point(@Lat,@Lon,4326)
	
select count(*)
from dbo.LocationsGeo2 
where 
	Location.STDistance(@g) < 1609 and 
	CompanyId = @CompanyId and
	@Lat between MinLat and MaxLat and 
	@Lon between MinLon and MaxLon
go


