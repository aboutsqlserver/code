/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*               Chapter 25. Query Optimization and Execution               */
/*                    Contradictions in Execution Plan                      */
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
		s.name = 'dbo' and t.name = 'PositiveNumbers'    
)
	drop table dbo.PositiveNumbers
go

if exists
(
	select * 
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'NegativeNumbers'
)
	drop table dbo.NegativeNumbers
go

create table dbo.PositiveNumbers(PositiveNumber int not null primary key)
create table dbo.NegativeNumbers(NegativeNumber int not null primary key)
go

;with CTE(Num)
as
(
	select 1

	union all

	select Num + 1
	from CTE 
	where Num < 1000
)
insert into dbo.NegativeNumbers(NegativeNumber)
	select -Num from CTE
option (MAXRECURSION 0)
go

;with CTE(Num)
as
(
	select 1

	union all

	select Num + 2
	from CTE 
	where Num < 1000
)
insert into dbo.PositiveNumbers(PositiveNumber)
	select Num from CTE
option (MAXRECURSION 0)
go

-- Enable "Include Actual Execution Plan"
select *
from dbo.PositiveNumbers e join dbo.NegativeNumbers o on
	e.PositiveNumber = o.NegativeNumber
go

alter table dbo.PositiveNumbers
add constraint CHK_IsNumberPositive
check (PositiveNumber > 0)
go

alter table dbo.NegativeNumbers
add constraint CHK_IsNumberNegative
check (NegativeNumber < 0)
go

select *
from dbo.PositiveNumbers e join dbo.NegativeNumbers o on
	e.PositiveNumber = o.NegativeNumber
go


