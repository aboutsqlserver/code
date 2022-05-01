/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    Chapter 05: Nonclustered Indexes                      */
/*                           01.SARGability                                 */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go


if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Customers_OnDisk' and s.name = 'dbo') drop table dbo.Customers_OnDisk;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Customers' and s.name = 'dbo') drop table dbo.Customers;
go

create table dbo.Customers
(
	CustomerId int identity(1,1) not null
		constraint PK_Customers
		primary key nonclustered 
		hash with (bucket_count=1000),
	FirstName varchar(32) 
		collate Latin1_General_100_BIN2 not null,
	LastName varchar(64) 
		collate Latin1_General_100_BIN2 not null,
	FullName varchar(97) 
		collate Latin1_General_100_BIN2 not null,

	index IDX_LastName_FirstName 
	nonclustered(LastName, FirstName),

	index IDX_FullName
	nonclustered(FullName)
) 
with (memory_optimized=on, durability=schema_only);

create table dbo.Customers_OnDisk
(
	CustomerId int identity(1,1) not null,
	FirstName varchar(32) not null,
	LastName varchar(64) not null,
	FullName varchar(97) not null,

	constraint PK_Customers_OnDisk
	primary key clustered(CustomerId)
);

create nonclustered index IDX_Customers_OnDisk_LastName_FirstName 
on dbo.Customers_OnDisk(LastName, FirstName);

create nonclustered index IDX_Customers_OnDisk_FullName
on dbo.Customers_OnDisk(FullName);
go

;with FirstNames(FirstName)
as
(
	select Names.Name
	from
	(
		values('Andrew'),('Andy'),('Anton'),('Ashley'),('Boris'),
		('Brian'),('Cristopher'),('Cathy'),('Daniel'),('DONALD'),
		('Edward'),('Eddy'),('Emy'),('Frank'),('George'),('Harry'),
		('Henry'),('Ida'),('John'),('Jimmy'),('Jenny'),('Jack'),
		('Kathy'),('Kim'),('Larry'),('Mary'),('Max'),('Nancy'),
		('Olivia'),('Paul'),('Peter'),('Patrick'),('Robert'),
		('Ron'),('Steve'),('Shawn'),('Tom'),('Timothy'),
		('Uri'),('Vincent')
	) Names(Name)
)
,LastNames(LastName)
as
(
	select Names.Name
	from
	(
		values('Smith'),('Johnson'),('Williams'),('Jones'),('Brown'),
		('Davis'),('Miller'),('Wilson'),('Moore'),('Taylor'),
		('Anderson'),('Jackson'),('White'),('Harris')
	) Names(Name)
)
insert into dbo.Customers(LastName, FirstName, FullName)
	select LastName, FirstName, FirstName + ' ' + LastName
	from FirstNames cross join LastNames;

insert into dbo.Customers_OnDisk(LastName, FirstName, FullName)
	select LastName, FirstName, FullName
	from dbo.Customers;
go

/* Check Execution Plans */

/* SARGable Predicates */
-- Point-Lookup specifying all columns in the index
select CustomerId, FirstName, LastName
from dbo.Customers
where LastName = 'White' and FirstName = 'Paul';

-- Point-lookup using leftmost index column
select CustomerId, FirstName, LastName
from dbo.Customers
where LastName = 'White'; 

-- Using ">", ">=", "<", "<=" comparison
select CustomerId, FirstName, LastName
from dbo.Customers
where LastName > 'White'; 

-- Prefix Search
select CustomerId, FirstName, LastName
from dbo.Customers
where LastName like 'Wh%'; 

-- IN list
select CustomerId, FirstName, LastName
from dbo.Customers
where LastName in ('White','Moore');


/* Non-SARGable Predicates */
-- Omitting left-most index column(s)
select CustomerId, FirstName, LastName
from dbo.Customers
where FirstName = 'Paul';

-- Substring Search
select CustomerId, FirstName, LastName
from dbo.Customers
where LastName like '%hit%';

-- Functions
select CustomerId, FirstName, LastName
from dbo.Customers
where len(LastName) = 5;

/* Sorting in the direction of the index key */
select top 3 CustomerId, FirstName, LastName, FullName
from dbo.Customers_OnDisk
order by FullName ASC;

select top 3 CustomerId, FirstName, LastName, FullName
from dbo.Customers
order by FullName ASC;

/* Sorting in the direction opposite to the index key */
select top 3 CustomerId, FirstName, LastName, FullName
from dbo.Customers_OnDisk
order by FullName DESC;

select top 3 CustomerId, FirstName, LastName, FullName
from dbo.Customers
order by FullName DESC;
