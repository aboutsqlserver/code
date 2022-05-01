/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 15. CLR Types                            */
/*                             HierarchyId                                  */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'HierarchyTest') drop table dbo.HierarchyTest;
go


create table dbo.HierarchyTest
(
	ID hierarchyid not null,
	Level tinyint not null
)
go


/*** Adding Children as rightmost nodes ***/
declare
	@MaxLevels int = 7
	,@ItemPerLevel int = 8
	,@Level int = 2

insert into dbo.HierarchyTest(ID, Level) values(hierarchyid::GetRoot(), 1);

while @Level <= @MaxLevels
begin
	;with CTE(ID, Child, Num)
	as
	 (
		select ID, ID.GetDescendant(null,null), 1 
		from dbo.HierarchyTest
		where Level = @Level - 1

		union all
		
		select ID, ID.GetDescendant(Child,null), Num + 1
		from CTE  
		where Num < @ItemPerLevel
	)
	insert into dbo.HierarchyTest(ID, Level)
		select Child, @Level
		from CTE 
	option (maxrecursion 0);

	set @Level += 1;
end;
go

select avg(datalength(ID)) from dbo.HierarchyTest;
go

/*** Adding Children in-between Existing Nodes ***/
truncate table dbo.HierarchyTest
go

declare
	@MaxLevels int = 7
	,@ItemPerLevel int = 8
	,@Level int = 2

insert into dbo.HierarchyTest(ID, Level) values(hierarchyid::GetRoot(), 1);

while @Level <= @MaxLevels
begin
	;with CTE(ID, Child, PrevChild, Num)
	as
	 (
		select ID, ID.GetDescendant(null,null), convert(hierarchyid,null), 1 
		from dbo.HierarchyTest
		where Level = @Level - 1

		union all
		
		select ID, 
			case 
				when PrevChild < Child 
				then ID.GetDescendant(PrevChild, Child) 
				else ID.GetDescendant(Child, PrevChild) 
			end, Child, Num + 1
		from CTE  
		where Num < @ItemPerLevel
	)
	insert into dbo.HierarchyTest(ID, Level)
		select Child, @Level
		from CTE 
	option (maxrecursion 0);

	set @Level += 1;
end;
go

select avg(datalength(ID)) from dbo.HierarchyTest;
go
