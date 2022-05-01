/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                Chapter 18. Troubleshooting Blocking Issues               */
/*                      Setting Blocked Process Threshold                  */
/****************************************************************************/

sp_configure 'show advanced options', 1;
go
reconfigure;
go
sp_configure 'blocked process threshold', 20;
go
reconfigure;
go
