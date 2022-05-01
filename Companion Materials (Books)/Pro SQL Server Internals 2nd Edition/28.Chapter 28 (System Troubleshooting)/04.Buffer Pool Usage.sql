/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapter 28. System Troubleshooting                     */
/*                           Buffer Pool Usage                              */
/****************************************************************************/

/*** Buffer Pool Usage on Per-Database Basis ***/
select	
	database_id as [DB ID]
	,db_name(database_id) as [DB Name]
	,convert(decimal(11,3),count(*) * 8 / 1024.0) as 
		[Buffer Pool Size (MB)]
from sys.dm_os_buffer_descriptors with (nolock)
group by database_id
order by [Buffer Pool Size (MB)] desc
option (recompile);
go

