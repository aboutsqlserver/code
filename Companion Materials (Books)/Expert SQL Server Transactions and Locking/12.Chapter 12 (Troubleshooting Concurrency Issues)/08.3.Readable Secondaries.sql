/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 12. Troubleshooting Concurrency Issues              */
/*                    Readable Secondaries (Session 2)                      */
/****************************************************************************/

-- Run on Primary node

use SQLServerInternals
go

delete from dbo.T1;
go

-- Waiting 1 minute
waitfor delay '00:01:00.000';

-- You will notice high number of reads even though the table is empty
set statistics io on
select count(*) from dbo.T1;
set statistics io off
go

select index_id, index_level, page_count, record_count, version_ghost_record_count
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.T1'),1,NULL,'DETAILED');
go

