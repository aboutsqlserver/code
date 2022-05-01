/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 01. Data Storage Internals                     */
/*            Check if Instant File Initialization is Enabled               */
/****************************************************************************/

use master
go

/*** Checking to see if Instant File Initialization is enabled ***/
dbcc traceon(3004,3605,-1)
go

create database Dummy
go

exec sp_readerrorlog
go

drop database Dummy
go

dbcc traceoff(3004,3605,-1)
go

