/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                Chapter 18. Troubleshooting Blocking Issues               */
/*                      Setting Blocked Process Threshold                   */
/****************************************************************************/

sp_configure 'show advanced options', 1;
go
reconfigure;
go
sp_configure 'blocked process threshold', 20; -- In seconds.
go
reconfigure;
go
