/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                      Chapter 15. Data Partitioning                       */
/*                     Moving Data Between Disk Arrays                      */
/****************************************************************************/

set nocount on
go

use master
go

/****************************************************************************/
/* Below is just example how you can move data between different filegroups */
/****************************************************************************/

-- STEP 1: Adding file(s) to the new disk array
alter database OrderEntryDB
add file 
( 
	name = N'Orders2013_03', 
	filename = N'S:\Orders2013_03.ndf'
) 
to filegroup [FG2013];

alter database OrderEntryDB
add file 
( 
	name = N'Orders2013_04', 
	filename = N'S:\Orders2013_04.ndf'
) 
to filegroup [FG2013]
go

use OrderEntryDb
go

-- STEP 2: Shrinking and removing first old file
dbcc shrinkfile(Orders2013_01, emptyfile);
alter database OrderEntryDb remove file Orders2013_01
go

-- STEP 3: Shrinking and removing second old file
dbcc shrinkfile(Orders2013_02, emptyfile);
alter database OrderEntryDb remove file Orders2013_02
go

-- Monitoring progress
select 
	name as [FileName]
	,physical_name as [Path]
	,size / 128.0 as [CurrentSizeMB]
	,size / 128.0 - convert(int,fileproperty(name,'SpaceUsed')) / 
		128.0 as [FreeSpaceMb]
from sys.database_files
