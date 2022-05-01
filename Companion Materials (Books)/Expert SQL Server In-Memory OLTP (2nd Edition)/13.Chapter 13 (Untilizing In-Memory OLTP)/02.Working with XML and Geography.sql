/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 13: Utilizing In-Memory OLTP                     */
/*                   02.Working with XML and Geography                      */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop table if exists dbo.DeviceEvents; 
go

/* 
create table dbo.DeviceEvents
(
	DeviceId int not null,
	EventTime datetime2(0) not null, 
	Location geography not null,
	EventInfo xml not null,
);

create unique clustered index IDX_DeviceEvents_DeviceId_EventTime
on dbo.DeviceEvents(DeviceId, EventTime);
*/


create table dbo.DeviceEvents
(
	DeviceId int not null,
	EventTime datetime2(0) not null, 
	Lat decimal(9,6) not null,
	Long decimal(9,6) not null,
	EventInfo varbinary(max) not null,

    constraint PK_DeviceEvents
    primary key nonclustered(DeviceId, EventTime)
)
with (memory_optimized = on, durability = schema_only);

insert into dbo.DeviceEvents(DeviceId, EventTime, Lat, Long, EventInfo)
values
	(1,'2017-03-01T08:00:00',48.6062,-122.3321 
		,convert(varbinary(max),'<Event Code=''1'' Sensor1=''ON'' />'))
	,(2,'2017-03-01T09:00:00',45.5231,-122.6765 
		,convert(varbinary(max),'<Event Code=''2'' Sensor1=''OFF'' />'));


declare
	@Loc geography = geography::Point(47.65600,-122.36000, 4326);

;with DeviceData(DeviceId, EventTime, Location, EventInfo)
as
(
	select
		DeviceId, EventTime
		,geography::Point(Lat, Long, 4326) as Location
		,convert(xml,EventInfo) as EventInfo
	from dbo.DeviceEvents
)
select
	DeviceId, EventTime
	,Location.STDistance(@Loc) as Distance
	,EventInfo.value('/Event[1]/@Code','int') as [Code]
	,EventInfo.value('/Event[1]/@Sensor1','varchar(3)') as [Status]
from DeviceData;