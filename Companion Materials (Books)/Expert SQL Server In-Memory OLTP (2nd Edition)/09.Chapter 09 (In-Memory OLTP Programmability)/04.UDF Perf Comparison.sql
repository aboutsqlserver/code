/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 09: In-Memory OLTP Programmability                 */
/*           04.User-Defined Functions Performance Comparison               */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go



drop function if exists dbo.ScalarInterpret;
drop function if exists dbo.ScalarNativelyCompiled;
go


create function dbo.ScalarInterpret(@LoopCnt int)
returns int
as
begin
	declare
		@I int = 0;
	while @I < @LoopCnt
		select @I += 1;
	return @I;
end
go

create function dbo.ScalarNativelyCompiled(@LoopCnt int)
returns int
with native_compilation, schemabinding  
as   
begin atomic with (transaction isolation level = snapshot, language = N'English')  
	declare
		@I int = 0;
	while @I < @LoopCnt
		select @I += 1;
	return @I;
end
go

declare
	@Start datetime = getdate()

select dbo.ScalarInterpret(10000000);
select datediff(millisecond,@Start,getDate()) as [Interpred];
select @Start = getDate();
select dbo.ScalarNativelyCompiled(10000000);
select datediff(millisecond,@Start,getDate()) as [Natively Compiled];
go

set nocount on
go

declare
	@Start datetime = getdate()
	,@Dummy int
	,@I int = 0

while @I < 1000000
begin
	select @Dummy = dbo.ScalarInterpret(0);
	select @I += 1;
end
select datediff(millisecond,@Start,getDate()) as [Interpred];

select @Start = getDate(), @I = 0;
while @I < 1000000
begin
	select @Dummy = dbo.ScalarNativelyCompiled(0);
	select @I += 1;
end
select datediff(millisecond,@Start,getDate()) as [Natively Compiled];
go


