/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 03. Statistics                           */
/*                   SQL Server 2016 Cardinality Estimator    `             */
/****************************************************************************/

set noexec off
go

use [SqlServerInternals]
go

if convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) < 13 
begin
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

drop table if exists dbo.CETestRef;
drop table if exists dbo.CETest;
go


-- The script changes Database Compatibility Model - you can run it with every statement
-- and observe the difference in the behavior. 
-- You can also enable legacy cardinality estimator in the database compatibility settings

-- Remember to check the model in the root element of the execution plan (SELECT)
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
	select ID,dateadd(day,abs(checksum(newid())) % 365,'2016-06-01') 
	from IDs;

create unique clustered index IDX_CETest_ID on dbo.CETest(ID);
create nonclustered index IDX_CETest_ADate on dbo.CETest(ADate);
go

dbcc show_statistics('dbo.CETest',IDX_CETest_ADate);
go

-- Enable "Include Actual Execution Plan"
-- Check estimated # of rows vs. actual

/* Up-to-date Statistics */

-- TEST 1: Value is a key in the histogram (Validate your data)

-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 110; -- CE 70
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 120; -- CE 120
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 130; -- CE 130 SQL Server 2016
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2016-06-24';
go

-- TEST 2: Value is a not a key in the histogram (Validate your data)

-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 110; -- CE 70
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 120; -- CE 120
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 130; -- CE 130 SQL Server 2016
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2016-06-23';

-- TEST 3: Unknown Value

-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 110; -- CE 70
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 120; -- CE 120
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 130; -- CE 130 SQL Server 2016
declare
	@D date = '2016-06-25' ;

select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = @D;

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

-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 110; -- CE 70
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 120; -- CE 120
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 130 ;-- CE 130 SQL Server 2016
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2016-06-24';
go

-- TEST 2: Value is a not a key in the histogram (Validate your data)

-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 110; -- CE 70
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 120; -- CE 120
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 130; -- CE 130 SQL Server 2016
select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = '2016-06-23';

-- TEST 3: Unknown Value

-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 110; -- CE 70
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 120; -- CE 120
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 130 ;-- CE 130 SQL Server 2016
declare
	@D date = '2016-06-25' 

select ID, ADate, Placeholder
from dbo.CETest with (index=IDX_CETest_ADate)
where ADate = @D;


/* Ever-increasing keys  */

dbcc show_statistics('dbo.CETest',IDX_CETest_ID);
go

-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 110; -- CE 70
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 120; -- CE 120
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 130; -- CE 130 SQL Server 2016
select top 10 ID, ADate 
from dbo.CETest
where ID between 66000 and 67000
order by PlaceHolder;

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

-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 110; -- CE 70
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 120; -- CE 120
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 130; -- CE 130 SQL Server 2016
select d.ID 
from dbo.CETestRef d join dbo.CETest m on 
	d.ID = m.ID;
go


/* Multiple Predicates  */

-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 110; -- CE 70
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 120; -- CE 120
-- ALTER DATABASE [SQLServerInternals] SET COMPATIBILITY_LEVEL = 130; -- CE 130 SQL Server 2016
select ID, ADate
from dbo.CETest
where 
	ID between 20000 and 30000 and 
	ADate between '2017-01-01' and '2017-02-01';

