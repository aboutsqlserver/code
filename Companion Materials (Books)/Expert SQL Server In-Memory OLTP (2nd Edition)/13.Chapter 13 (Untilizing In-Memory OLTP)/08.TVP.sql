/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 13: Utilizing In-Memory OLTP                     */
/*                      06.Batch Insert Performance                         */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2016
go

/****************************************************************************/
/*  This script prepares the database schema for SaveRecordSetApp demo app  */
/****************************************************************************/

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertDataRecordsTVP' and s.name = 'dbo') drop proc dbo.InsertDataRecordsTVP;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertDataRecordsElementsXml' and s.name = 'dbo') drop proc dbo.InsertDataRecordsElementsXml;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertDataRecordsAttrXml' and s.name = 'dbo') drop proc dbo.InsertDataRecordsAttrXml;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertDataRecordsOpenXML' and s.name = 'dbo') drop proc dbo.InsertDataRecordsOpenXML;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where p.name = 'InsertDataRecordsAttrXml2' and s.name = 'dbo') drop proc dbo.InsertDataRecordsAttrXml2;
if exists(select * from sys.types t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'DataRecordsTVP' and s.name = 'dbo')	drop type dbo.DataRecordsTVP;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'DataRecords') drop table dbo.DataRecords;
go

create table dbo.DataRecords
(
	ID int not null,
	Col1 varchar(20) not null,
	Col2 varchar(20) not null,	
	Col3 varchar(20) not null,	
	Col4 varchar(20) not null,	
	Col5 varchar(20) not null,
	Col6 varchar(20) not null,	
	Col7 varchar(20) not null,	
	Col8 varchar(20) not null,	
	Col9 varchar(20) not null,
	Col10 varchar(20) not null,	
	Col11 varchar(20) not null,	
	Col12 varchar(20) not null,	
	Col13 varchar(20) not null,
	Col14 varchar(20) not null,	
	Col15 varchar(20) not null,	
	Col16 varchar(20) not null,	
	Col17 varchar(20) not null,
	Col18 varchar(20) not null,	
	Col19 varchar(20) not null,	
	Col20 varchar(20) not null,
	
	constraint PK_DataRecords
	primary key clustered(ID)
)
go


create type dbo.DataRecordsTVP as Table
(
	ID int not null,
	Col1 varchar(20) not null,
	Col2 varchar(20) not null,	
	Col3 varchar(20) not null,	
	Col4 varchar(20) not null,	
	Col5 varchar(20) not null,
	Col6 varchar(20) not null,	
	Col7 varchar(20) not null,	
	Col8 varchar(20) not null,	
	Col9 varchar(20) not null,
	Col10 varchar(20) not null,	
	Col11 varchar(20) not null,	
	Col12 varchar(20) not null,	
	Col13 varchar(20) not null,
	Col14 varchar(20) not null,	
	Col15 varchar(20) not null,	
	Col16 varchar(20) not null,	
	Col17 varchar(20) not null,
	Col18 varchar(20) not null,	
	Col19 varchar(20) not null,	
	Col20 varchar(20) not null,
	
	primary key(ID)
	--primary key nonclustered hash(ID) with (bucket_count=65536)
)	
--with (memory_optimized=on);
go	

create proc dbo.InsertDataRecordsTVP
(
	@Data dbo.DataRecordsTVP READONLY
)
as
begin
	set xact_abort on
	set transaction isolation level read committed
	set nocount on
	
	begin tran
		insert into dbo.DataRecords(ID,Col1,Col2,Col3,Col4,Col5,
			Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
			Col14,Col15,Col16,Col17,Col18,Col19,Col20)
			select ID,Col1,Col2,Col3,Col4,Col5,
				Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
				Col14,Col15,Col16,Col17,Col18,Col19,Col20
			from @Data
	commit
end
go

create proc dbo.InsertDataRecordsElementsXml
(
	@Data xml
)
as
begin
	set xact_abort on
	set transaction isolation level read committed
	set nocount on
	
	begin tran
		insert into dbo.DataRecords(ID,Col1,Col2,Col3,Col4,Col5,
			Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
			Col14,Col15,Col16,Col17,Col18,Col19,Col20)
		SELECT
			Rows.n.value('ID[1]', 'int')
			,Rows.n.value('F1[1]', 'varchar(20)')
			,Rows.n.value('F2[1]', 'varchar(20)') 
			,Rows.n.value('F3[1]', 'varchar(20)') 
			,Rows.n.value('F4[1]', 'varchar(20)') 
			,Rows.n.value('F5[1]', 'varchar(20)') 
			,Rows.n.value('F6[1]', 'varchar(20)') 
			,Rows.n.value('F7[1]', 'varchar(20)') 
			,Rows.n.value('F8[1]', 'varchar(20)') 
			,Rows.n.value('F9[1]', 'varchar(20)') 
			,Rows.n.value('F10[1]', 'varchar(20)') 
			,Rows.n.value('F11[1]', 'varchar(20)') 
			,Rows.n.value('F12[1]', 'varchar(20)') 
			,Rows.n.value('F13[1]', 'varchar(20)') 
			,Rows.n.value('F14[1]', 'varchar(20)') 
			,Rows.n.value('F15[1]', 'varchar(20)') 
			,Rows.n.value('F16[1]', 'varchar(20)') 
			,Rows.n.value('F17[1]', 'varchar(20)') 
			,Rows.n.value('F18[1]', 'varchar(20)') 
			,Rows.n.value('F19[1]', 'varchar(20)') 
			,Rows.n.value('F20[1]', 'varchar(20)') 
		FROM 
			@Data.nodes('//Recs/R') Rows(n)
	commit
end
go

create proc dbo.InsertDataRecordsAttrXml
(
	@Data xml
)
as
begin
	set xact_abort on
	set transaction isolation level read committed
	set nocount on
	
	begin tran
		insert into dbo.DataRecords(ID,Col1,Col2,Col3,Col4,Col5,
			Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
			Col14,Col15,Col16,Col17,Col18,Col19,Col20)
		SELECT
			Rows.n.value('@ID[1]', 'int')
			,Rows.n.value('@F1[1]', 'varchar(20)')
			,Rows.n.value('@F2[1]', 'varchar(20)') 
			,Rows.n.value('@F3[1]', 'varchar(20)') 
			,Rows.n.value('@F4[1]', 'varchar(20)') 
			,Rows.n.value('@F5[1]', 'varchar(20)') 
			,Rows.n.value('@F6[1]', 'varchar(20)') 
			,Rows.n.value('@F7[1]', 'varchar(20)') 
			,Rows.n.value('@F8[1]', 'varchar(20)') 
			,Rows.n.value('@F9[1]', 'varchar(20)') 
			,Rows.n.value('@F10[1]', 'varchar(20)') 
			,Rows.n.value('@F11[1]', 'varchar(20)') 
			,Rows.n.value('@F12[1]', 'varchar(20)') 
			,Rows.n.value('@F13[1]', 'varchar(20)') 
			,Rows.n.value('@F14[1]', 'varchar(20)') 
			,Rows.n.value('@F15[1]', 'varchar(20)') 
			,Rows.n.value('@F16[1]', 'varchar(20)') 
			,Rows.n.value('@F17[1]', 'varchar(20)') 
			,Rows.n.value('@F18[1]', 'varchar(20)') 
			,Rows.n.value('@F19[1]', 'varchar(20)') 
			,Rows.n.value('@F20[1]', 'varchar(20)') 
		FROM 
			@Data.nodes('//Recs/R') Rows(n)
	commit
end
go

create proc dbo.InsertDataRecordsOpenXML
(
	@Data xml
)
as
begin
	set xact_abort on
	set transaction isolation level read committed
	set nocount on

	declare
		@Result int
		,@Handle int

	exec @Result = sp_xml_preparedocument @Handle output, @Data
	if (@Result <> 0)
	begin
		raiserror('Cannot get xml handle',17,1);
		return
	end
	
	begin tran
		insert into dbo.DataRecords(ID,Col1,Col2,Col3,Col4,Col5,
			Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
			Col14,Col15,Col16,Col17,Col18,Col19,Col20)
		SELECT
			ID, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10,
			F11, F12, F13, F14, F15, F16, F17, F18, F19, F20
		from 
			OPENXML (@Handle, '/Recs/R',1)
		with
			(ID int, F1 varchar(20), F2 varchar(20), F3 varchar(20), 
			F4 varchar(20), F5 varchar(20), F6 varchar(20), F7 varchar(20), 
			F8 varchar(20), F9 varchar(20), F10 varchar(20), F11 varchar(20), 
			F12 varchar(20), F13 varchar(20), F14 varchar(20), F15 varchar(20), 
			F16 varchar(20), F17 varchar(20), F18 varchar(20), F19 varchar(20), 
			F20 varchar(20))
	commit
	exec sp_xml_removedocument @Handle	
end
go

create proc dbo.InsertDataRecordsAttrXml2
(
	@Data xml
)
as
begin
	set xact_abort on
	set transaction isolation level read committed
	set nocount on
	
	declare
		@Temp table 
		(
			ID int not null,
			Col1 varchar(20) not null,
			Col2 varchar(20) not null,	
			Col3 varchar(20) not null,	
			Col4 varchar(20) not null,	
			Col5 varchar(20) not null,
			Col6 varchar(20) not null,	
			Col7 varchar(20) not null,	
			Col8 varchar(20) not null,	
			Col9 varchar(20) not null,
			Col10 varchar(20) not null,	
			Col11 varchar(20) not null,	
			Col12 varchar(20) not null,	
			Col13 varchar(20) not null,
			Col14 varchar(20) not null,	
			Col15 varchar(20) not null,	
			Col16 varchar(20) not null,	
			Col17 varchar(20) not null,
			Col18 varchar(20) not null,	
			Col19 varchar(20) not null,	
			Col20 varchar(20) not null
		)			

	insert into @Temp(ID,Col1,Col2,Col3,Col4,Col5,
			Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
			Col14,Col15,Col16,Col17,Col18,Col19,Col20)
		SELECT
			Rows.n.value('@ID[1]', 'int')
			,Rows.n.value('@F1[1]', 'varchar(20)')
			,Rows.n.value('@F2[1]', 'varchar(20)') 
			,Rows.n.value('@F3[1]', 'varchar(20)') 
			,Rows.n.value('@F4[1]', 'varchar(20)') 
			,Rows.n.value('@F5[1]', 'varchar(20)') 
			,Rows.n.value('@F6[1]', 'varchar(20)') 
			,Rows.n.value('@F7[1]', 'varchar(20)') 
			,Rows.n.value('@F8[1]', 'varchar(20)') 
			,Rows.n.value('@F9[1]', 'varchar(20)') 
			,Rows.n.value('@F10[1]', 'varchar(20)') 
			,Rows.n.value('@F11[1]', 'varchar(20)') 
			,Rows.n.value('@F12[1]', 'varchar(20)') 
			,Rows.n.value('@F13[1]', 'varchar(20)') 
			,Rows.n.value('@F14[1]', 'varchar(20)') 
			,Rows.n.value('@F15[1]', 'varchar(20)') 
			,Rows.n.value('@F16[1]', 'varchar(20)') 
			,Rows.n.value('@F17[1]', 'varchar(20)') 
			,Rows.n.value('@F18[1]', 'varchar(20)') 
			,Rows.n.value('@F19[1]', 'varchar(20)') 
			,Rows.n.value('@F20[1]', 'varchar(20)') 
		FROM 
			@Data.nodes('//Recs/R') Rows(n)
	
	begin tran
		insert into dbo.DataRecords(ID,Col1,Col2,Col3,Col4,Col5,
			Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
			Col14,Col15,Col16,Col17,Col18,Col19,Col20)
		SELECT
			ID,Col1,Col2,Col3,Col4,Col5,
			Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
			Col14,Col15,Col16,Col17,Col18,Col19,Col20
		from @Temp
	commit
end
go
