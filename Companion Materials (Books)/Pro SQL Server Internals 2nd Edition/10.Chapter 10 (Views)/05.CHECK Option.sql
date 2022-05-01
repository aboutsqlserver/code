/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                           Chapter 10. Views                              */
/*                        Views with CHECK OPTION                           */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'vPositiveNumbers') drop view dbo.vPositiveNumbers;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Numbers') drop table dbo.Numbers;
go

create table dbo.Numbers(Number int)
go

create view dbo.vPositiveNumbers(Number)
as
	select Number
	from dbo.Numbers
	where Number > 0
with check option;
go

-- Success
insert into dbo.vPositiveNumbers(Number) values(1);
go

-- Failure
insert into dbo.vPositiveNumbers(Number) values(-1);
go

-- Failure
update dbo.vPositiveNumbers set Number = -1 where Number = 1;
go

select * from dbo.Numbers;
go

