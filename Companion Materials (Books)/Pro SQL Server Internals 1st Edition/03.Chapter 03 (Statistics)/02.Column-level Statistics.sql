/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 03. Statistics                           */
/*                        Column-level Statistics                           */
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
		s.name = 'dbo' and t.name = 'Customers'    
)
	drop table dbo.Customers
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
on dbo.Customers(CustomerId)
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

insert into dbo.Customers(LastName, FirstName) values('Korotkevitch','Dmitri')
go

create nonclustered index IDX_Customers_LastName_FirstName
on dbo.Customers(LastName, FirstName)
go

-- Enable "Include Actual Execution Plan"
select CustomerId, FirstName, LastName, Phone
from dbo.Customers
where FirstName = 'Brian';

select CustomerId, FirstName, LastName, Phone
from dbo.Customers
where FirstName = 'Dmitri'
go

select  stats_id, name, auto_created
from sys.stats
where object_id = object_id(N'dbo.Customers')
go

declare
	@statname sysname

set @statname = 
	(
		select  name
		from sys.stats
		where 
			object_id = object_id(N'dbo.Customers') and
			name like '_WA%'
	)      

if @statname is not null
	dbcc show_statistics('dbo.Customers',@statname)		
go

dbcc show_statistics('dbo.Books',IDX_BOOKS_ISBN) 
go


