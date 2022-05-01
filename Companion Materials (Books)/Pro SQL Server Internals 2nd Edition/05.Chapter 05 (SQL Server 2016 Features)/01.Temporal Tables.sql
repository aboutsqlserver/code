/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 05. SQL Server 2016 Feautes                    */
/*                 Dmitri Korotkevitch with Thomas Grohser                  */
/*                           Temporal Tables                                */
/****************************************************************************/

use [SqlServerInternals]
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on t.schema_id = s.schema_id 
	where s.name = 'dbo' and t.name = 'CompanyEmployees' and t.temporal_type = 2
) 
	alter table dbo.CompanyEmployees set (system_versioning = off);
go

drop table if exists dbo.CompanyEmployeesHistory;
drop table if exists dbo.CompanyEmployees;
go

create table dbo.CompanyEmployees
(
	EmployeeId int not null,
	FullName nvarchar(128) not null,
	Position nvarchar(128) not null,
	Salary money not null,
	SysStartTime datetime2 
		generated always as row start not null,
	SysEndTime datetime2 
		generated always as row end not null,
	constraint PK_CompanyEmployees
	primary key clustered(EmployeeId),
	
	period for system_time(SysStartTime, SysEndTime)
)
with 
(
	system_versioning = on (history_table = dbo.CompanyEmployeesHistory)
);

create nonclustered index IDX_CompanyEmployees_FullName
on dbo.CompanyEmployees(FullName);
go

-- Populating Data
insert into dbo.CompanyEmployees(EmployeeId, FullName, Position, Salary)
values
	(1,'John Doe','Database Administrator',85000),
	(2,'David Black','Sr. Software Developer',95000),
	(3,'Mike White','QA Engineer',75000);

waitfor delay '00:01:00.000';

update dbo.CompanyEmployees set Salary = 85500 where EmployeeID = 1;
delete from dbo.CompanyEmployees where EmployeeId = 2;

select 'dbo.CompanyEmployees' as [Table], *,'','' from dbo.CompanyEmployees;
select 'dbo.CompanyEmployeesHistory' as [Table], *,'','' from dbo.CompanyEmployeesHistory;
go

-- Check Execution Plans.
select * from dbo.CompanyEmployees;
go

-- You need to change time in FOR SYSTEM_TIME AS clause to get correct results
-- You can use SysStartTime, SysEndTime from the current table to analyze it
select *
from dbo.CompanyEmployees 
	for system_time as of '2016-09-14T10:33:00'; 

select * 
from dbo.CompanyEmployees 
	for system_time from '2016-09-14T10:32:56.7738153' to '2016-09-14T10:33:56.7738153';
	 
select * 
from dbo.CompanyEmployees 
	for system_time between '2016-09-14T10:32:56.7738153' and '2016-09-14T10:33:56.7738153';
	 
select *
from dbo.CompanyEmployees 
	for system_time contained in ('2016-09-14T10:32:00', '2016-09-14T10:34:00'); 
 
select * 
from dbo.CompanyEmployees 
	for system_time all 
order by employeeid;

-- Clean-up
alter table dbo.CompanyEmployees set (system_versioning = off);
drop table if exists dbo.CompanyEmployeesHistory;
drop table if exists dbo.CompanyEmployees;
go

