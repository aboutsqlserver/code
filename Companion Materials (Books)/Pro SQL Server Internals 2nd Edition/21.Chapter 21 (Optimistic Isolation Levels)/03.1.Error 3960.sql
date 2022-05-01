/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 21. Optimistic Isolation Levels				    */
/*              Snapshot Isolation and Error 3960 (Session 1)               */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

/*** Enabling snapshot ***/
alter database SqlServerInternals 
set allow_snapshot_isolation on; 
go


-- Step 1 -- starting transaction
set transaction isolation level snapshot
begin tran
	select * 
	from Delivery.Orders 
	where OrderId = 1000;

	-- Run Session 2 code
	
	-- Step 2
	update Delivery.Orders
	set Reference = convert(varchar(48),newid())
	where OrderId = 1;
commit
go


/*** Disabling Snapshot ***/
alter database SqlServerInternals 
set allow_snapshot_isolation off;
go
