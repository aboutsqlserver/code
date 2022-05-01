/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                      Chapter 22. Application Locks                       */
/*                             Table Creation                               */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'RawData'    
)
	drop table dbo.RawData
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
)
go


;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N4)
insert into dbo.RawData(ID) 
	select ID
	from IDs
go