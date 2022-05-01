/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                              Initial Setup                               */
/*                          Creating the Database                           */
/****************************************************************************/
set noexec off
go

-- This script creates DBA database. You can use existing database. 
-- Make sure that Service Broker is enabled 
--
-- You should configure the database files and filegroups according to the best practices

if exists
(
	select * 
	from sys.configurations 
	where name = N'blocked process threshold (s)' and value = 0
)
begin
	raiserror('Blocked Process Threshold is not set',16,1) with nowait;
	raiserror('You can enable it with the following statement',0,1) with nowait;
	raiserror(N'
sp_configure ''show advanced options'', 1;
go
reconfigure;
go
sp_configure ''blocked process threshold'', 10; -- time in seconds
go
reconfigure;
go',0,1) with nowait;
	set noexec on
end
go

if not exists
(
	select * 
	from sys.databases
	where name = 'DBA'
)
begin
	raiserror('Creating Database DBA',0,1) with nowait;
	create database DBA;
		 --COLLATE Latin1_General_BIN2; -- testing purposes
	exec sp_executesql 
		N'alter database DBA set enable_broker;
		alter database DBA set recovery simple;';
end
go
