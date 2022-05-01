/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 05. SQL Server 2016 Feautes                    */
/*                 Dmitri Korotkevitch with Thomas Grohser                  */
/*                          Row-Level Security                              */
/****************************************************************************/

use SQLServerInternals
go

drop security policy if exists LimitMgrFilter;
drop function if exists Client.fn_LimitToManager;
drop security policy if exists LimitMgrFilter2;
drop function if exists Client.fn_LimitToManager2;
drop function if exists Client.fn_checkCanUpdateVIP;
drop function if exists Client.fn_checkCanUpdateCreditLimit;
drop function if exists Client.fn_CurrentUserIsRegionalManager;
drop user if exists RegionalManager;
drop user if exists ClientManager1;
drop table if exists Client.Client1;
drop table if exists Client.Client2;
drop table if exists Client.ClientManager;
drop schema if exists Client;
go

create user ClientManager1 without login;
create user RegionalManager without login;
go

create schema Client;
go

create table Client.Client1
(
    ClientID int not null,
    ClientManager sysname not null,
    Revenue money not null,
    OtherInfo nvarchar(100) not null
);

grant select on Client.Client1 to ClientManager1, RegionalManager;
grant showplan to ClientManager1;

insert into Client.Client1 values
    (1, 'ClientManager1', 100000, 'abc')
    ,(2, 'ClientManager1', 200000, 'def')
    ,(3, 'ClientManager2', 300000, 'ghi')
    ,(4, 'ClientManager2', 400000, 'jkl')
    ,(5, 'ClientManager3', 500000, 'mno');
go

/* Impersonating */
execute as user = 'ClientManager1';
select * from Client.Client1;
revert;
go

create function Client.fn_LimitToManager(@Manager as sysname)
returns table
with schemabinding
as
return 
( 
	select 1 AS fn_LimitToManagerResult
	where @Manager = user_name() or user_name() = 'RegionalManager' 
)
go

create security policy LimitMgrFilter
add filter predicate Client.fn_LimitToManager(ClientManager)
on Client.Client1
with (state = on)
go

execute as user = 'ClientManager1';
select * from Client.Client1;
revert;
go

/* Performance Impact */
create table Client.ClientManager
(
    ID int not null 
        constraint PK_ClientManager primary key clustered,
    ManagerName nvarchar(100) not null,
    IsRegionalManager bit not null
);

insert into Client.ClientManager values
    (1,'ClientManager1',0), (2,'ClientManager2',0)
    ,(3,'ClientManager3',0), (4,'RegionalManager',1);

create table Client.Client2
(
    ClientID int not null,
    ClientManagerID int not null
        constraint FK_Client2_ClientManager
        foreign key references Client.CLientManager(ID),
    ClientName nvarchar(64) not null,
    CreditLimit money not null,
    IsVIP bit not null
        constraint DEF_Client2_IsVIP default 0
);

grant select on Client.Client2 to ClientManager1, RegionalManager;
grant showplan to ClientManager1;
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2) -- 65,536 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N5)
insert into Client.Client2(ClientID, ClientManagerID, ClientName, CreditLimit, IsVip) 
    select ID, ID % 3 + 1, convert(nvarchar(6),ID), 100000, abs(sign(ID % 10) - 1)
    from IDS
go

create function Client.fn_LimitToManager2(@ManagerID int)
	returns table
with schemabinding
as
return 
( select 1 as fn_LimitToManagerResult
  from Client.ClientManager
  where ManagerName = user_name() 
    and ((ID = @ManagerID) or (IsRegionalManager = 1)) )
go

create security policy LimitMgrFilter2
add filter predicate Client.fn_LimitToManager2(ClientManagerID)
on Client.Client2
with (state = on);
go

select * from Client.ClientManager;
select * from Client.Client2;

-- Check Execution Plan
execute as user = 'ClientManager1';
select user_name()
select * from Client.Client2 
revert;
go

create index IDX_ClientManager_ManagerName 
on Client.ClientManager(ManagerName) 
include(IsRegionalManager) 
go

-- Check Execution Plan
execute as user = 'ClientManager1';
select user_name()
select * from Client.Client2 
revert;
go

/* Block Predicate */
create function Client.fn_CurrentUserIsRegionalManager()
returns table 
with schemabinding
as
return
(
    select 1 as Result
	from Client.ClientManager
	where ManagerName = user_name() and IsRegionalManager = 1
)
go

create function Client.fn_checkCanUpdateVIP(@IsVIP bit)
returns table
with schemabinding
as
return
(
    select 1 as CanUpdateClient
	where 
		case 
			when @IsVip = 0 then 1
			else (select Result from Client.fn_CurrentUserIsRegionalManager())
		end = 1
)
go

alter security policy LimitMgrFilter2
add block predicate Client.fn_checkCanUpdateVIP(IsVip) on Client.Client2 before update;
go

select * from Client.Client2 
where ClientManagerID = 1 and IsVip = 1 -- ID: 60

select * from Client.Client2 
where ClientManagerID = 1 and IsVip = 0 -- ID: 12

grant update on Client.Client2 to ClientManager1, RegionalManager;

execute as user = 'ClientManager1';
select * from Client.Client2 where ClientId in (12, 60);
update Client.Client2 set CreditLimit = 50000 where ClientId = 60;
select * from Client.Client2 where ClientId in (12, 60);
revert;
go

execute as user = 'RegionalManager';
select * from Client.Client2 where ClientId in (12, 60);
update Client.Client2 set CreditLimit = 50000 where ClientId = 60;
select * from Client.Client2 where ClientId in (12, 60);
revert;
go

create function Client.fn_checkCanUpdateCreditLimit(@CreditLimit money)
returns table
with schemabinding
as
return
(
    select 1 as CanUpdateClient
	where 
		case 
			when @CreditLimit <= 100000 then 1
			else (select Result from Client.fn_CurrentUserIsRegionalManager())
		end = 1
)
go

alter security policy LimitMgrFilter2
add block predicate Client.fn_checkCanUpdateCreditLimit(CreditLimit) on Client.Client2 after update;
go

execute as user = 'ClientManager1';
select * from Client.Client2 where ClientId in (12, 60);
update Client.Client2 set ClientManagerId = 2 where ClientId = 24;
select * from Client.Client2 where ClientId in (12, 60);
revert;
go

