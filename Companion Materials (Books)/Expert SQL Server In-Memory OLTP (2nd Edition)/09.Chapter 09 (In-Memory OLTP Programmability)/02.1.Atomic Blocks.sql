/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 09: In-Memory OLTP Programmability                 */
/*                       02.Atomic Blocks (Session 1)                       */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

drop proc if exists dbo.AtomicBlockDemo;
drop table if exists dbo.MOData;

create table dbo.MOData
(
	ID int not null
		primary key nonclustered
		hash with (bucket_count=16),
	Value int null
)
with (memory_optimized=on, durability=schema_only);

insert into dbo.MOData(ID, Value) 
values	
	(1,1), (2,2)
go

create proc dbo.AtomicBlockDemo
(
	@ID1 int not null
	,@Value1 bigint not null
	,@ID2 int 
	,@Value2 bigint 
)
with native_compilation, schemabinding, execute as owner
as
begin atomic
with (transaction isolation level = snapshot, language=N'us_english')
	update dbo.MOData set Value = @Value1 where ID = @ID1
	if @ID2 is not null
		update dbo.MOData set Value = @Value2 where ID = @ID2
end
go

/*** Non-Critical Errors ***/
-- Step 1
begin tran
	exec dbo.AtomicBlockDemo 1, -1, 2, -2
	exec dbo.AtomicBlockDemo 1, 0, 2, 999999999999999

	-- Step 2
	select @@TRANCOUNT as [@@TRANCOUNT], XACT_STATE() as [XACT_STATE()]
commit
go
select * from dbo.MOData
go

/*** Critical Errors ***/
-- Step 1
begin tran
	exec dbo.AtomicBlockDemo 1, 0, null, null

	/*** Run Session 2 code to trigger write/write conflict ***/
	-- Step 2
	select @@TRANCOUNT as [@@TRANCOUNT], XACT_STATE() as [XACT_STATE()]
commit
go
select * from dbo.MOData
go