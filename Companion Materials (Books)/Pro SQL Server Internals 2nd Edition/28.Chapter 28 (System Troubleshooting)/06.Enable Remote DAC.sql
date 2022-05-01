/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 28. System Troubleshooting                     */
/*                      Enable Remote DAC Connection                        */
/****************************************************************************/

exec sp_configure 'remote admin connections', 1 ;
go
reconfigure;
go
