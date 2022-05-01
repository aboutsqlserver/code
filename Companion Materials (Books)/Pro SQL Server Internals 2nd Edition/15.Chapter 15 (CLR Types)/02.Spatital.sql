/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 15. CLR Types                            */
/*                            Spatial Types                                 */
/****************************************************************************/

/****************************************************************************/
/* Ypu can improve spatial types performance by using T6533 and T6534       */
/* in  SQL Server 2012 SP3 and SQL Server 2014 SP2                          */
/****************************************************************************/


set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*   That script uses objects created by "01.Object Creation.sql" script    */
/*                  from "14.Chapter 14 (CLR)" Chapter                      */
/****************************************************************************/


if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Locations') drop table dbo.Locations;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'LocationsGeo') drop table dbo.LocationsGeo;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'LocationsGeoIndexed') drop table dbo.LocationsGeoIndexed;
go

create table dbo.Locations
(
	Id int not null identity(1,1),
	Latitude decimal(9,6) not null,
	Longitude decimal(9,6) not null,
	primary key(Id)
);

create table dbo.LocationsGeo
(
	Id int not null identity(1,1),
	Location geography not null,
	primary key(Id)
);  

create table dbo.LocationsGeoIndexed
(
	Id int not null identity(1,1),
	Location geography not null,
	primary key(Id)
);

-- 241,402 rows
;with Latitudes(Lat)
as
(
	select convert(float,40.0)
	union all
	select convert(float,Lat + 0.01)
	from Latitudes
	where Lat < convert(float,48.0)
)
,Longitudes(Lon)
as
(
	select convert(float,-120.0)
	union all
	select Lon - 0.01
	from Longitudes
	where Lon > -123
)
insert into dbo.Locations(Latitude, Longitude)
	select Latitudes.Lat, Longitudes.Lon
	from Latitudes cross join Longitudes
option (maxrecursion 0);

insert into dbo.LocationsGeo(Location)
	select geography::Point(Latitude, Longitude, 4326)
	from dbo.Locations;

insert into dbo.LocationsGeoIndexed(Location)
	select Location
	from dbo.LocationsGeo;

create spatial index Idx_LocationsGeoIndexed_Spatial
on dbo.LocationsGeoIndexed(Location);
go


-- Enable "Include Actual Execution Plan"

declare
	@Lat decimal(9,6) = 47.620309
	,@Lon decimal(9,6) = -122.349563

declare
	@G geography = geography::Point(@Lat,@Lon,4326)

set statistics time on

select ID
from dbo.Locations
where dbo.CalcDistanceCLR(Latitude, Longitude, @Lat, @Lon) < 1609;

select ID
from dbo.LocationsGeo
where Location.STDistance(@G) < 1609;

select ID
from dbo.LocationsGeoIndexed
where Location.STDistance(@G) < 1609;

set statistics time off
go
