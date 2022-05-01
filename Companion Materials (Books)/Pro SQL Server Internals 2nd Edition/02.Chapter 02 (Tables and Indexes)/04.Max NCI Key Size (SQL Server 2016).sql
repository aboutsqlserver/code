/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*  Chapter 02. Tables and Indexes: Internal Structure and Access Methods   */
/*        Nonclustered Index Key Size Limitation (SQL Server 2016)          */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'LargeKeys') drop table dbo.LargeKeys;
go

create table dbo.LargeKeys
(
	Col1 varchar(1000) not null,
	Col2 varchar(1000) not null
);

-- Success with the warining
create nonclustered index IDX_NCI on dbo.LargeKeys(Col1,Col2);
go

-- Success:
insert into dbo.LargeKeys(Col1, Col2) values('Small','Small');
go

-- Failure:
insert into dbo.LargeKeys(Col1, Col2) values(replicate('A',900),replicate('B',900));
go