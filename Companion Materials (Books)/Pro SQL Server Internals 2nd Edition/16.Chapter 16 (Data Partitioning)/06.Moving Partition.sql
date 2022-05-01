/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 16. Data Partitioning                       */
/*         Moving Partition to Another Filegroup using Staging Table        */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*			This script requires Enterprise Edition of SQL Server.			*/
/*	    You can rebuild indexes to different filegroups in non-Enterprise   */ 
/*                             Editions offline			                    */
/****************************************************************************/

if convert(int, serverproperty('EngineEdition')) != 3
begin
	raiserror('That script requires Enterprise Edition of SQL Server to run',16,1);
	set noexec on
end
go

if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where s.name = 'dbo' and v.name = 'OrderData') drop view dbo.OrderData;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'tblOrderData' and s.name = 'dbo') drop table dbo.tblOrderData;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'tblOrderDataStage' and s.name = 'dbo') drop table dbo.tblOrderDataStage;
if exists(select * from sys.partition_schemes where name = 'psOrderData') drop partition scheme psOrderData;
if exists(select * from sys.partition_functions where name = 'pfOrderData') drop partition function pfOrderData;
go

create partition function pfOrderData(datetime)
as range right for values 
('2016-02-01','2016-03-01','2016-04-01'
,'2016-05-01','2016-06-01','2016-07-01');

create partition scheme psOrderData 
as partition pfOrderData
to (FG2016,FG2016,FG2016,FG2016,FASTSTORAGE,FASTSTORAGE,FASTSTORAGE);

create table dbo.tblOrderData
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
);

create unique clustered index IDX_tblOrderData_OrderDate_OrderId
on dbo.tblOrderData(OrderDate, OrderId) 
on psOrderData(OrderDate);

create nonclustered index IDX_tblOrderData_CustomerId
on dbo.tblOrderData(CustomerId) 
on psOrderData(OrderDate);
go

create view dbo.OrderData(OrderId, OrderDate, OrderNum
	,OrderTotal, CustomerId /*Other Columns*/)
as
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.tblOrderData;
go

create table dbo.tblOrderDataStage
(
	OrderId int not null,
	OrderDate datetime not null,
	OrderNum varchar(32) not null,
	OrderTotal money not null,
	CustomerId int not null,
	/* Other Columns */
	constraint CHK_tblOrderDataStage
	check(OrderDate >= '2016-05-01' and OrderDate < '2016-06-01')
);

create unique clustered index IDX_tblOrderDataStage_OrderDate_OrderId
on dbo.tblOrderDataStage(OrderDate, OrderId)
on [FASTSTORAGE]; 

create nonclustered index IDX_tblOrderDataStage_CustomerId
on dbo.tblOrderDataStage(CustomerId) 
on [FASTSTORAGE];
go

alter table dbo.tblOrderData switch partition 5 to dbo.tblOrderDataStage;
go

alter view dbo.OrderData(OrderId, OrderDate, OrderNum
	,OrderTotal, CustomerId /*Other Columns*/)
as
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.tblOrderData
	union all
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.tblOrderDataStage
go

create trigger dbo.trgOrderDataView_Ins
on dbo.OrderData
instead of insert
as
	if @@rowcount = 0 return
	set nocount on
	if not exists(select * from inserted)
		return	
	insert into dbo.tblOrderData(OrderId, OrderDate
		,OrderNum, OrderTotal, CustomerId)
		select OrderId, OrderDate, OrderNum
			,OrderTotal, CustomerId
		from inserted
		where 
			OrderDate < '2016-05-01' or 
			OrderDate >= '2016-06-01'
       
	insert into dbo.tblOrderDataStage(OrderId, OrderDate
		,OrderNum, OrderTotal, CustomerId)
		select OrderId, OrderDate, OrderNum
			,OrderTotal, CustomerId
		from inserted
		where 
			OrderDate >= '2016-05-01' and 
			OrderDate < '2016-06-01'
go

create trigger dbo.trgOrderDataView_Upd
on dbo.OrderData
instead of update
as

	if @@rowcount = 0 return;
	set nocount on
	if not exists(select * from inserted i join deleted d on i.OrderId = d.OrderId)
		return;

	update t
	set
		t.OrderDate = i.OrderDate
		,t.OrderNum = i.OrderNum
		,t.OrderTotal = i.OrderTotal
		,t.CustomerId = i.CustomerId
	from
		dbo.tblOrderData t join inserted i on
			t.OrderId = i.OrderId
	where
		i.OrderDate < '2016-05-01' or 
		i.OrderDate >= '2016-06-01';

	update t
	set
		t.OrderDate = i.OrderDate
		,t.OrderNum = i.OrderNum
		,t.OrderTotal = i.OrderTotal
		,t.CustomerId = i.CustomerId
	from
		dbo.tblOrderDataStage t join inserted i on
			t.OrderId = i.OrderId
	where
		i.OrderDate >= '2016-05-01' or 
		i.OrderDate < '2016-06-01';
go

create trigger dbo.trgOrderDataView_Del
on dbo.OrderData
instead of delete
as
	if @@rowcount = 0 return;
	set nocount on
	if not exists(select * from deleted)
		return;	

	delete from dbo.tblOrderData 
	where 
		OrderId in 
		(
			select OrderId 
			from deleted
			where
				OrderDate < '2016-05-01' or 
				OrderDate >= '2016-06-01'
		);

	delete from dbo.tblOrderDataStage 
	where 
		OrderId in 
		(
			select OrderId 
			from deleted
			where
				OrderDate >= '2016-05-01' or 
				OrderDate < '2016-06-01'
		);
go

create unique clustered index IDX_tblOrderDataStage_OrderDate_OrderId
on dbo.tblOrderDataStage(OrderDate, OrderId)
with (drop_existing=on, online=on)
on [FG2016]; 

create nonclustered index IDX_tblOrderDataStage_CustomerId
on dbo.tblOrderDataStage(CustomerId) 
with (drop_existing=on, online=on)
on [FG2016]; 
go

alter partition function pfOrderData()
merge range ('2016-05-01');

alter partition scheme psOrderData
next used [FG2016];

alter partition function pfOrderData()
split range ('2016-05-01'); 

alter table dbo.tblOrderDataStage 
switch to dbo.tblOrderData partition 5; 

drop trigger dbo.trgOrderDataView_Ins;
drop trigger dbo.trgOrderDataView_Upd;
drop trigger dbo.trgOrderDataView_Del;
go

alter view dbo.OrderData(OrderId, OrderDate, OrderNum
	,OrderTotal, CustomerId /*Other Columns*/)
with schemabinding
as
	select OrderId, OrderDate, OrderNum
		,OrderTotal, CustomerId /*Other Columns*/
	from dbo.tblOrderData;
go

