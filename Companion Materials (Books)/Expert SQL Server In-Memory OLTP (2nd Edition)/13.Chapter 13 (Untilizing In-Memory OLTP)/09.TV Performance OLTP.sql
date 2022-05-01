/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. Temporary Objects and TempDB                   */
/*              Inserting Batch of Rows from the Client App                 */
/*            SQL Server 2016 version (includes JSON support)               */
/****************************************************************************/

/****************************************************************************/
/* This script prepares database structure for SaveResultSet application.   */
/* You can find the application in .Net subfolder in the source codes.      */
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
	raiserror('You should have SQL Server 2016 to execute this script',16,1) with nowait
	set noexec on
end
go

use [InMemoryOLTP2016]
go

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'InsertDataRecordsTVP') drop proc dbo.InsertDataRecordsTVP;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'InsertDataRecordsElementsXml') drop proc dbo.InsertDataRecordsElementsXml;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'InsertDataRecordsAttrXml') drop proc dbo.InsertDataRecordsAttrXml;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'InsertDataRecordsOpenXML') drop proc dbo.InsertDataRecordsOpenXML;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'InsertDataRecordsAttrXml2') drop proc dbo.InsertDataRecordsAttrXml2;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'InsertDataRecordsJSON') drop proc dbo.InsertDataRecordsJSON;
if exists(select * from sys.types t join sys.schemas s on t.schema_id = s.schema_id	where s.name = 'dbo' and t.name = 'DataRecordsTVP') drop type dbo.DataRecordsTVP;
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
	
	--primary key(ID)
	primary key nonclustered hash(ID) with (bucket_count=65536)
)	
with (memory_optimized=on);
go	

create proc dbo.InsertDataRecordsTVP
(
	@Data dbo.DataRecordsTVP READONLY
)
as
	insert into dbo.DataRecords(ID,Col1,Col2,Col3,Col4,Col5,
		Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
		Col14,Col15,Col16,Col17,Col18,Col19,Col20)
		select ID,Col1,Col2,Col3,Col4,Col5,
			Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
			Col14,Col15,Col16,Col17,Col18,Col19,Col20
		from @Data;
go

create proc dbo.InsertDataRecordsElementsXml
(
	@Data xml
)
as
	insert into dbo.DataRecords(ID,Col1,Col2,Col3,Col4,Col5,
		Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
		Col14,Col15,Col16,Col17,Col18,Col19,Col20)
	select
		Rows.n.value('ID[1]', 'int')
		,Rows.n.value('(F1/text())[1]', 'varchar(20)')
		,Rows.n.value('(F2/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F3/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F4/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F5/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F6/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F7/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F8/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F9/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F10/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F11/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F12/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F13/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F14/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F15/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F16/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F17/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F18/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F19/text())[1]', 'varchar(20)') 
		,Rows.n.value('(F20/text())[1]', 'varchar(20)') 
	from 
		@Data.nodes('//Recs/R') Rows(n);
go

create proc dbo.InsertDataRecordsAttrXml
(
	@Data xml
)
as
	insert into dbo.DataRecords(ID,Col1,Col2,Col3,Col4,Col5,
		Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
		Col14,Col15,Col16,Col17,Col18,Col19,Col20)
	select
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
	from 
		@Data.nodes('//Recs/R') Rows(n);
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
		select
			ID, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10,
			F11, F12, F13, F14, F15, F16, F17, F18, F19, F20
		from 
			openxml (@Handle, '/Recs/R',1)
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
		select
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
		from 
			@Data.nodes('//Recs/R') Rows(n)
	
	begin tran
		insert into dbo.DataRecords(ID,Col1,Col2,Col3,Col4,Col5,
			Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
			Col14,Col15,Col16,Col17,Col18,Col19,Col20)
		select
			ID,Col1,Col2,Col3,Col4,Col5,
			Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
			Col14,Col15,Col16,Col17,Col18,Col19,Col20
		from @Temp
	commit
end
go

create proc dbo.InsertDataRecordsJSON
(
	@Data nvarchar(max)
)
as
	insert into dbo.DataRecords(ID,Col1,Col2,Col3,Col4,Col5,
		Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
		Col14,Col15,Col16,Col17,Col18,Col19,Col20)
		select ID,Col1,Col2,Col3,Col4,Col5,
			Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
			Col14,Col15,Col16,Col17,Col18,Col19,Col20
		from 
			openjson(@Data,'$')
			with
			(
				ID int '$.ID',
				Col1 varchar(20) '$.F1',
				Col2 varchar(20) '$.F2', 
				Col3 varchar(20) '$.F3', 
				Col4 varchar(20) '$.F4', 
				Col5 varchar(20) '$.F5', 
				Col6 varchar(20) '$.F6', 
				Col7 varchar(20) '$.F7', 
				Col8 varchar(20) '$.F8', 
				Col9 varchar(20) '$.F9', 
				Col10 varchar(20) '$.F10', 
				Col11 varchar(20) '$.F11', 
				Col12 varchar(20) '$.F12', 
				Col13 varchar(20) '$.F13', 
				Col14 varchar(20) '$.F14', 
				Col15 varchar(20) '$.F15', 
				Col16 varchar(20) '$.F16', 
				Col17 varchar(20) '$.F17', 
				Col18 varchar(20) '$.F18', 
				Col19 varchar(20) '$.F19', 
				Col20 varchar(20) '$.F20' 
			);
go