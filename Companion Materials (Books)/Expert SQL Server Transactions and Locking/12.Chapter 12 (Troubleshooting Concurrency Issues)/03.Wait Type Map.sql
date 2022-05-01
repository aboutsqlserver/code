/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 12. Troubleshooting Concurrency Issues              */
/*                         Wait Type Map Values                             */
/****************************************************************************/

-- Identifying map type values for wait_info Extended Event
select name, map_key, map_value
from sys.dm_xe_map_values
where name = 'wait_types'
order by map_key
