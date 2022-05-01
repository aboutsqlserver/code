/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 16. Data Partitioning                       */
/*             Switching a Staging Table as the New Partition               */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*			This script requires Enterprise Edition of SQL Server.			*/
/****************************************************************************/

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'MainData') drop table dbo.MainData;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'StagingData') drop table dbo.StagingData;
if exists(select * from sys.partition_schemes where name = 'psMainData') drop partition scheme psMainData;
if exists(select * from sys.partition_functions where name = 'pfMainData') drop partition function pfMainData;
go

create partition function pfMainData(datetime)
as range right for values 
('2016-02-01', '2016-03-01','2016-04-01','2016-05-01','2016-06-01','2016-07-01'
,'2016-08-01','2016-09-01','2016-10-01','2016-11-01','2016-12-01');

create partition scheme psMainData 
as partition pfMainData
all to (FG2016);

/* Even though we have 12 partitions - one per month, let's assume 
that only January-May data is populated. E.g. we are in the middle
of the year */
create table dbo.MainData
(
	ADate datetime not null,
	ID bigint not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_MainData
	primary key clustered(ADate, ID)
	on psMainData(ADate)
);

create nonclustered index IDX_MainData_CustomerId
on dbo.MainData(CustomerId)
on psMainData(ADate);

create table dbo.StagingData
(
	ADate datetime not null,
	ID bigint not null,
	CustomerId int not null,
	/* Other Columns */
	constraint PK_StagingData
	primary key clustered(ADate, ID),

	constraint CHK_StagingData
	check(ADate >= '2016-05-01' and ADate < '2016-06-01')
) on [FG2016];

create nonclustered index IDX_StagingData_CustomerId
on dbo.StagingData(CustomerId)
on [FG2016];

/* Switching partition */
alter table dbo.StagingData 
switch to dbo.MainData
partition 5;
go
