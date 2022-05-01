/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*             Chapter 04. Special Indexng and Storage Feautes              */
/*                      Indexes with Included Columns                       */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Customers') drop table dbo.Customers;
go

create table dbo.Customers
(
	CustomerId int not null identity(1,1),
	FirstName  nvarchar(64) not null,
	LastName nvarchar(128) not null,
	Phone varchar(32) null,
	Placeholder char(200) null
);

create unique clustered index IDX_Customers_CustomerId
on dbo.Customers(CustomerId);
go

-- Inserting cross-joined data for all first and last names 50 times 
-- using GO 50 command in Management Studio
;with FirstNames(FirstName)
as
(
	/*select Names.Name
	from 
	(
		values('Andrew'),('Andy'),('Anton'),('Ashley'),('Boris'),
		('Brian'),('Cristopher'),('Cathy'),('Daniel'),('Donny'),
		('Edward'),('Eddy'),('Emy'),('Frank'),('George'),('Harry'),
		('Henry'),('Ida'),('John'),('Jimmy'),('Jenny'),('Jack'),
		('Kathy'),('Kim'),('Larry'),('Mary'),('Max'),('Nancy'),
		('Olivia'),('Olga'),('Peter'),('Patrick'),('Robert'),
		('Ron'),('Steve'),('Shawn'),('Tom'),('Timothy'),
		('Uri'),('Vincent')
	) Names(Name) */
	select 'Andrew' union all select 'Andy' union all select 'Anton' union all 
	select 'Ashley' union all select 'Boris' union all select 'Brian' union all 
	select 'Cristopher' union all select 'Cathy' union all select 'Daniel' union all 
	select 'Donny' union all select 'Edward' union all select 'Eddy' union all 
	select 'Emy' union all select 'Frank' union all select 'George' union all select 'Harry' union all
	select 'Henry' union all select 'Ida' union all select 'John' union all select 'Jimmy' union all 
	select 'Jenny' union all select 'Jack' union all select 'Kathy' union all select 'Kim' union all 
	select 'Larry' union all select 'Mary' union all select 'Max' union all select 'Nancy' union all 
	select 'Olivia' union all select 'Olga' union all select 'Peter' union all select 'Patrick' union all 
	select 'Robert' union all select 'Ron' union all select 'Steve' union all select 'Shawn' union all 
	select 'Tom' union all select 'Timothy' union all select  'Uri' union all select 'Vincent'
)
,LastNames(LastName)
as
(
	/*select Names.Name
	from 
	(
		values('Smith'),('Johnson'),('Williams'),('Jones'),('Brown'),
			('Davis'),('Miller'),('Wilson'),('Moore'),('Taylor'),
			('Anderson'),('Jackson'),('White'),('Harris')
	) Names(Name) */
	select 'Smith' union all select'Johnson' union all select'Williams' union all select'Jones' union all 
	select'Brown' union all select 'Davis' union all select'Miller' union all select'Wilson' union all 
	select'Moore' union all select'Taylor' union all select 'Anderson' union all select'Jackson' union all 
	select'White' union all select'Harris'
) 
insert into dbo.Customers(LastName, FirstName)
	select LastName, FirstName
	from FirstNames cross join LastNames 		
go 50

insert into dbo.Customers(LastName, FirstName) values('Korotkevitch','Dmitri');
go

create nonclustered index IDX_Customers_LastName_FirstName
on dbo.Customers(LastName, FirstName);
go


-- Enable "Include Actual Execution Plan"
set statistics io on

select CustomerId, LastName, FirstName, Phone
from dbo.Customers
where LastName = 'Smith';

select CustomerId, LastName, FirstName, Phone
from dbo.Customers with (Index=IDX_Customers_LastName_FirstName)
where LastName = 'Smith';

set statistics io off
go

create nonclustered index IDX_Customers_LastName_FirstName_PhoneIncluded
on dbo.Customers(LastName, FirstName)
include(Phone);
go

set statistics io on

select CustomerId, LastName, FirstName, Phone
from dbo.Customers
where LastName = 'Smith';

set statistics io off
go


/* Update overhead */
update dbo.Customers
set Placeholder = 'Placeholder'
where CustomerId = 1;

update dbo.Customers
set Phone = '505-123-4567'
where CustomerId = 1;
go


/* Included vs. Key columns */
if exists(select * from sys.indexes i join sys.tables t on i.object_id = t.object_id join sys.schemas s on s.schema_id = t.schema_id where s.name = 'dbo' and t.name = 'Customers' and i.name = 'IDX_Customers_LastName_FirstName_PhoneIncluded')
	drop index IDX_Customers_LastName_FirstName_PhoneIncluded on dbo.Customers;
if exists(select * from sys.indexes i join sys.tables t on i.object_id = t.object_id join sys.schemas s on s.schema_id = t.schema_id where s.name = 'dbo' and t.name = 'Customers' and i.name = 'IDX_Customers_LastName_FirstName')
	drop index IDX_Customers_LastName_FirstName on dbo.Customers;

create index IDX_Key on dbo.Customers(LastName, FirstName);
create index IDX_Include on dbo.Customers(LastName) include(FirstName);
go

set statistics io on

select CustomerId, LastName, FirstName 
from dbo.Customers  with (index = IDX_Key)
where LastName = 'Smith';

select CustomerId, LastName, FirstName 
from dbo.Customers  with (index = IDX_Include)
where LastName = 'Smith';

set statistics io off
go

set statistics io on

select CustomerId, LastName, FirstName 
from dbo.Customers  with (index = IDX_Key)
where LastName = 'Smith' and FirstName = 'Andrew';

select CustomerId, LastName, FirstName 
from dbo.Customers  with (index = IDX_Include)
where LastName = 'Smith' and FirstName = 'Andrew';

set statistics io off
go