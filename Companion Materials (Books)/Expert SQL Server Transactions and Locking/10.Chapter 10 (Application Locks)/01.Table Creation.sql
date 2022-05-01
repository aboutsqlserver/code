/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 10. Application Locks                       */
/*                             Tables Creation                              */
/****************************************************************************/

set nocount on
go

use [SQLServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'RawData') drop table dbo.RawData;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'CollectedData') drop table dbo.CollectedData;
go

create table dbo.RawData
(
	ID int not null,
	Attributes char(100) not null
		constraint DEF_RawData_Attributes
		default 'Other columns',
	ProcessingTime datetime not null
		constraint DEF_RawData_ProcessingTime
		default '2010-01-01',
	
	constraint PK_RawData
	primary key clustered(ID)
);
go


;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N4)
insert into dbo.RawData(ID) 
	select ID
	from IDs;
go

create table dbo.CollectedData
(
	TenantId int not null,
	OnDate datetime not null,
	Id bigint not null identity(1,1),
	Attributes char(100) not null
		constraint DEF_CollectedData_Attributes
		default 'Other columns'
);

create unique clustered index IDX_CollectedData_TenantId_OnDate_Id
on dbo.CollectedData(TenantId,OnDate,Id);
go

declare
	@OnDate datetime = '2018-06-01'

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N4)
insert into dbo.CollectedData(TenantId,OnDate)
	select ID % 3, dateadd(minute,ID,@OnDate)
	from IDs;
go
