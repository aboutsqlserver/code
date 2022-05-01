/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                         Chapter 03. Statistics                           */
/*                    SQL Server 2014 Cardinality Estimator                 */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/*** IMPORTANT: This demo requires SQL Server 2014                        ***/
/****************************************************************************/

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'CETest'    
)
	drop table dbo.CETest
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'CETestRef'    
)
	drop table dbo.CETestRef
go

create table dbo.CETest
(
	ID int not null,
	ADate date not null,
	Placeholder char(10)
);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
	insert into dbo.CETest(ID,ADate)
		select ID,dateadd(day,abs(checksum(newid())) % 365,'2013-06-01') 
		from IDs;

create unique clustered index IDX_CETest_ID
on dbo.CETest(ID);

create nonclustered index IDX_CETest_ADate
on dbo.CETest(ADate);
go

dbcc show_statistics('dbo.CETest',IDX_CETest_ADate)
go

-- Enable "Include Actual Execution Plan"
-- Check estimated # of rows vs. actual

/* Up-to-date Statistics */

-- TEST 1: Value is a key in the histogram (Validate your data)

-- New Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2013-06-24'

-- Legacy Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2013-06-24'
option (querytraceon 9481)
go

-- TEST 2: Value is a not a key in the histogram (Validate your data)

-- New Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2013-06-23'

-- Legacy Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2013-06-23'
option (querytraceon 9481)

-- TEST 3: Unknown Value

declare
	@D date = '2013-06-25' 

-- New Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = @D

-- Legacy Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = @D
option (querytraceon 9481);



/* Statistics is not up-to-date  */

-- Adding 10% more rows
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
	insert into dbo.CETest(ID,ADate)
		select ID + 65536,dateadd(day,abs(checksum(newid())) % 365,'2013-06-01') 
		from IDs
		where ID <= 6554;
go

-- TEST 1: Value is a key in the histogram (Validate your data)

-- New Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2013-06-24'

-- Legacy Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2013-06-24'
option (querytraceon 9481)
go

-- TEST 2: Value is a not a key in the histogram (Validate your data)

-- New Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2013-06-23'

-- Legacy Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2013-06-23'
option (querytraceon 9481)

-- TEST 3: Unknown Value

declare
	@D date = '2013-06-25' 

-- New Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = @D

-- Legacy Cardinality Estimator
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = @D
option (querytraceon 9481);
go


/* Ever-increasing keys  */

dbcc show_statistics('dbo.CETest',IDX_CETest_ID)
go

-- New Cardinality Estimator
select top 10 ID, ADate 
from dbo.CETest
where ID between 66000 and 67000
order by PlaceHolder;

-- Legacy Cardinality Estimator
select top 10 ID, ADate
from dbo.CETest
where ID between 66000 and 67000
order by PlaceHolder
option (querytraceon 9481);
go

/* Joins  */

create table dbo.CETestRef
(
	ID int not null,

	constraint FK_CTTestRef_CTTest
	foreign key(ID)
	references dbo.CETest(ID)
);

-- 72,089 rows
insert into dbo.CETestRef(ID)
	select ID from dbo.CETest;

create unique clustered index IDX_CETestRef_ID
on dbo.CETestRef(ID);

select d.ID 
from dbo.CETestRef d join dbo.CETest m on 
	d.ID = m.ID
go


/* Multiple Predicates  */
-- New Cardinality Estimator
select ID, ADate
from dbo.CETest
where 
	ID between 20000 and 30000 and 
	ADate between '2014-01-01' and '2014-02-01';

-- Legacy Cardinality Estimator
select ID, ADate
from dbo.CETest
where 
	ID between 20000 and 30000 and 
	ADate between '2014-01-01' and '2014-02-01'
option (querytraceon 9481);
