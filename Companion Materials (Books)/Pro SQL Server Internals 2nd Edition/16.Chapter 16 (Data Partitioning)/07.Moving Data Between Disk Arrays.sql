/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 16. Data Partitioning                       */
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
	name = N'Orders2015_03', 
	filename = N'S:\Orders2015_03.ndf'
) 
to filegroup [FG2015];

alter database OrderEntryDB
add file 
( 
	name = N'Orders2015_04', 
	filename = N'S:\Orders2015_04.ndf'
) 
to filegroup [FG2015]
go

use OrderEntryDb
go

-- Preventing the second OLD file to grow
declare
	@MaxFileSizeMB int
	,@SQL nvarchar(max)
	
-- Obtaining current file size 	
select @MaxFileSizeMB = size / 128 + 1
from sys.database_files
where name = 'Orders2015_02';

set @SQL = N'alter database OrderEntryDb 
modify file(name=N''Orders2015_02'',maxsize=' + 
	convert(nvarchar(32),@MaxFileSizeMB) + N'MB);';

exec sp_executesql @SQL;


-- STEP 2: Shrinking and removing first old file
dbcc shrinkfile(Orders2015_01, emptyfile);
alter database OrderEntryDb remove file Orders2015_01;
go

-- STEP 3: Shrinking and removing second old file
dbcc shrinkfile(Orders2015_02, emptyfile);
alter database OrderEntryDb remove file Orders2015_02;
go

-- Monitoring progress
select 
	name as [FileName]
	,physical_name as [Path]
	,size / 128.0 as [CurrentSizeMB]
	,size / 128.0 - convert(int,fileproperty(name,'SpaceUsed')) / 
		128.0 as [FreeSpaceMb]
from sys.database_files;
