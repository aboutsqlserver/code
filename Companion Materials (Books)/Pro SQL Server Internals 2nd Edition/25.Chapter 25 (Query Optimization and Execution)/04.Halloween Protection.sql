/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 25. Query Optimization and Execution               */
/*                           Halloween Protection                           */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if object_id(N'dbo.ShouldUpdateData','FN') is not null drop function dbo.ShouldUpdateData;
if object_id(N'dbo.ShouldUpdateDataSchemaBound','FN') is not null drop function dbo.ShouldUpdateDataSchemaBound;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'HalloweenProtection') drop table dbo.HalloweenProtection;
go

create table dbo.HalloweenProtection
(
	Id int not null identity(1,1),
	Data int not null
)
go

-- Enable "Include Actual Execution Plan"
insert into dbo.HalloweenProtection(Data)
	select Data from dbo.HalloweenProtection;
go

-- Table Spools and UDF
create function dbo.ShouldUpdateData(@Id int)
returns bit
as
begin
	return (1);
end
go

create function dbo.ShouldUpdateDataSchemaBound(@Id int)
returns bit
with schemabinding
as
begin
	return (1);
end
go

update dbo.HalloweenProtection
set Data = 0
where dbo.ShouldUpdateData(ID) = 1;

update dbo.HalloweenProtection
set Data = 0
where dbo.ShouldUpdateDataSchemaBound(ID) = 1;
