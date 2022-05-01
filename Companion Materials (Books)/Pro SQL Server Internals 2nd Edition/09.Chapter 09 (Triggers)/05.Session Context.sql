/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                          Chapter 09. Triggers                            */
/*                             Session Context                              */
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
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait;
	set noexec on
end
go

use [SqlServerInternals]
go

if exists(select * from sys.triggers where name = 'trg_PreventAlterDropTable_WithAudit') drop trigger trg_PreventAlterDropTable_WithAudit on database;
drop table if exists dbo.AlterationEvents;
drop table if exists dbo.Test;
go

create table dbo.AlterationEvents
(
    OnDate datetime2(7) not null
        constraint DEF_AlterationEvents_OnDate
        default sysutcdatetime(),
    Succeed bit not null,
    RequestedBy varchar(255) not null,
    Description varchar(8000) not null,

    constraint PK_AlterationEvents
    primary key clustered(OnDate)
)
go

create trigger trg_PreventAlterDropTable_WithAudit on database
for alter_table
as
begin
    set nocount on
	declare
		@AlterationAllowed bit = 1
		,@RequestedBy varchar(255)
		,@Description varchar(8000)
    
    select
	    @AlterationAllowed = convert(bit,session_context(N'AlterationAllowed'))
		,@RequestedBy = convert(varchar(255),session_context(N'RequestedBy'))
		,@Description = convert(varchar(255),session_context(N'Description'));

    if (@AlterationAllowed != 1) or (IsNull(@RequestedBy,'') = '') or 
	    (IsNull(@Description,'') = '')
    begin
		set @AlterationAllowed = 0;
        print 'Table alteration is not allowed in such context';
        rollback;
    end;
	
	insert into dbo.AlterationEvents(Succeed,RequestedBy,Description)
	values(
		@AlterationAllowed
		,IsNull(@RequestedBy,'Not Provided')
		,IsNull(@Description,'Not Provided')
	);
end
go

create table dbo.Test(ID int);
go

-- Failed
alter table dbo.Test add ID3 int;
go

select * from dbo.AlterationEvents;
go

-- Succeed
exec sp_set_session_context @key = N'AlterationAllowed', @value = 1, @read_only = 0;
exec sp_set_session_context @key = N'RequestedBy', @value = 'Developers', @read_only = 0;
exec sp_set_session_context @key = N'Description', @value = 'Client App v1.0.1 Support', @read_only = 0;
alter table dbo.Test add ID3 int;
go

select * from dbo.AlterationEvents;
go

-- Clean-up
drop trigger trg_PreventAlterDropTable_WithAudit on database;
go
