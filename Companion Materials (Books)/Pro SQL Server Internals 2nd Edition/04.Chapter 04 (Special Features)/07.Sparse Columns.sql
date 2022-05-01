/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*             Chapter 04. Special Indexng and Storage Feautes              */
/*                           Sparse Columns                                 */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'SparseDemo') drop table dbo.SparseDemo;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'ColumnSetDemo') drop table dbo.ColumnSetDemo;
go

create table dbo.SparseDemo
(
	ID int not null,
	Col1 int sparse,
	Col2 varchar(32) sparse,
	Col3 int sparse
);

create table dbo.ColumnSetDemo
(
	ID int not null,
	Col1 int sparse,
	Col2 varchar(32) sparse,
	Col3 int sparse,
	SparseColumns xml column_set for all_sparse_columns
);

insert into dbo.SparseDemo(ID,Col1) values(1,1);
insert into dbo.SparseDemo(ID,Col3) values(2,2);
insert into dbo.SparseDemo(ID,Col1,Col2) values(3,3,'Col2');

insert into dbo.ColumnSetDemo(ID,Col1,Col2,Col3)
	select ID,Col1,Col2,Col3 from dbo.SparseDemo;
go

select 'SparseDemo' as [Table], * from dbo.SparseDemo;
select 'ColumnSetDemo' as [Table], * from dbo.ColumnSetDemo;
go

insert into dbo.ColumnSetDemo(ID, SparseColumns)
values(4, '<col1>4</col1><col2>Insert data through column_set</col2>');

update dbo.ColumnSetDemo 
set SparseColumns = '<col2>Update data through column_set</col2>'
where ID = 3;

select ID, Col1, Col2, Col3 from dbo.ColumnSetDemo where ID in (3,4);
go
