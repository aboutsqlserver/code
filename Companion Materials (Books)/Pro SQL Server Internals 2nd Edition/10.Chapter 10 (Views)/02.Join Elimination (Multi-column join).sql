/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 10. Views                              */
/*                   Join Elimination (Multi-Column Joins)                  */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'vPositions') drop view dbo.vPositions;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Positions') drop table dbo.Positions;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Devices') drop table dbo.Devices;
go

create table dbo.Devices
(
	CompanyId int not null,
	DeviceId int not null,
	DeviceName nvarchar(64) not null,
);

create unique clustered index IDX_Devices_CompanyId_DeviceId
on dbo.Devices(CompanyId, DeviceId);

create table dbo.Positions
(
	CompanyId int not null,
	OnTime datetime not null, -- better to use datetime2(0) in SQL Server 2008+
	RecId bigint not null,
	DeviceId int not null,
	Latitude decimal(9,6) not null,
	Longitute decimal(9,6) not null,

	constraint FK_Positions_Devices
	foreign key(CompanyId, DeviceId)
	references dbo.Devices(CompanyId, DeviceId)
);

create unique clustered index IDX_Positions_CompanyId_OnTime_RecId
on dbo.Positions(CompanyId, OnTime, RecId);

create nonclustered index IDX_Positions_CompanyId_DeviceId_OnTime
on dbo.Positions(CompanyId, DeviceId, OnTime);
go

create view dbo.vPositions(CompanyId, OnTime, RecId, DeviceId, DeviceName, Latitude, Longitude)
as
	select p.CompanyId, p.OnTime, p.RecId, p.DeviceId, d.DeviceName, p.Latitude, p.Longitute
	from dbo.Positions p join dbo.Devices d on	
		p.CompanyId = d.CompanyId and p.DeviceId = d.DeviceId;
go

-- Enable "Include Actual Execution Plan"

-- Join elimination does not work with composite FK constraint
select OnTime, DeviceId, Latitude, Longitude
from dbo.vPositions
where CompanyId = 1 and OnTime between '2016-01-01' and '2016-01-15';

