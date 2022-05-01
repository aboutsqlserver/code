/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*             Chapter 04. Special Indexng and Storage Feautes              */
/*                           Filtered Statistics                            */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
		) < 10 -- SQL Server 2005
begin
	raiserror('This script requires SQL Server 2008+ to execute',16,1) with nowait
	set noexec on
end
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Cars'    
)
	drop table dbo.Cars
go

create table dbo.Cars
(
	ID int not null identity(1,1),
	Make varchar(32) not null,
	Model varchar(32) not null
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N4)
,Models(Model)
as
(
	select Models.Model
	from (
		values('Yaris'),('Corolla'),('Matrix'),('Camry'),('Avalon'),('Sienna'),('Tacoma'),('Tundra')
		,('RAV4'),('Venza'),('Highlander'),('FJ Cruiser'), ('4Runner'),('Sequoia'),('Land Cruiser'),('Prius')
	) Models(Model)
)
insert into dbo.Cars(Make,Model)
	select 'Toyota', Model
	from Models cross join IDs;

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N4)
,Models(Model)
as
(
	select Models.Model
	from (
		values('Accord'),('Civic'),('CR-V'),('Crosstour'),('CR-Z'),('FCX Clarity'),('Fit'),('Insight')
		,('Odyssey'),('Pilot'),('Ridgeline')
	) Models(Model)
)
insert into dbo.Cars(Make,Model)
	select 'Honda', Model
	from Models cross join IDs;


create statistics stat_Cars_Make on dbo.Cars(Make);
create statistics stat_Cars_Model on dbo.Cars(Model);
go

-- Enable "Include Actual Execution Plan"
-- Check actual vs. estimated # of rows
select count(*) from dbo.Cars where Make = 'Toyota';
select count(*) from dbo.Cars where Model = 'Corolla';
select count(*) from dbo.Cars where Make = 'Toyota' and Model = 'Corolla';
go

create statistics stat_Cars_Toyota_Models 
on dbo.Cars(Model) 
where Make='Toyota'
go

select count(*) from dbo.Cars where Make = 'Toyota' and Model = 'Corolla';
go

