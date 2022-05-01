/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 37. In-Memory OLTP Programmability               */
/*                        Natively-Compiled Functions	                    */
/****************************************************************************/

set noexec off
go

if convert(int,
	left(
		convert(nvarchar(128), serverproperty('ProductVersion')),
		charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
	)
) < 13 
begin
	raiserror('You should have SQL Server s2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

if convert(int, serverproperty('EngineEdition')) != 3 or charindex('X64',@@Version) = 0
begin
	raiserror('That script requires 64-Bit Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

if not exists (select * from sys.databases where name = 'SQLServerInternalsHK')
begin
	raiserror('Create [SQLServerInternalsHK] database with "02.Create In-Memory OLTP DB.sql" script from "00.Init" project',16,1);
	set noexec on
end
go

use SQLServerInternalsHK
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


