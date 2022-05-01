/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 14. Locking and Columnstore Indexes                */
/*                   Nonclustered Columnstore Indexes                       */
/****************************************************************************/

use SQLServerInternals
go

drop index IDX_Test_ID on dbo.Test;
drop index CCI_Test on dbo.Test;
go

create unique clustered index CI_Test_ID
on dbo.Test(ID);

create nonclustered columnstore index NCCI_Test
on dbo.Test(ID,Col)
with (maxdop=1);
go

-- Repeat all test and notice that there is no blocking