/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. Temporary Objects and TempDB                   */
/*                   Table Variables and Transactions                       */
/****************************************************************************/

/*** Statement-Level Rollback ***/
declare
	@T table(ID int not null primary key)

-- Success
insert into @T(ID) values(1);

-- Error: primary key violation
--insert into @T(ID) values(2),(3),(3)
insert into @T(ID) 
	select 2 union all select 3 union all select 3;

-- 1 row
select * from @T;
go

/*** Transaction rollback ***/
declare
	@Errors table
	(
		RecId int not null,
		[Error] nvarchar(512) not null,

		primary key(RecId)
	)
	;
begin tran
	-- Insert error information
	insert into @Errors(RecId, [Error])
	values(11,'Price mistake');

	insert into @Errors(RecId, [Error])
	values(42,'Insufficient stock');
rollback
/* Do something with errors */
select RecId, [Error] from @Errors;
go

