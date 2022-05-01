/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                   Chapter 27. System Troubleshooting                     */
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

