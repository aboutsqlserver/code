/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                   Chapter 01. Data Storage Internals                     */
/*           Check if Instant File Initialization is enabled                */
/****************************************************************************/

use [SqlServerInternals]
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

