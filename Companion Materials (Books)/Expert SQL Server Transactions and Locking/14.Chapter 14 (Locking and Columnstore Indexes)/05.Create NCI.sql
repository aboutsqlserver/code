/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 14. Locking and Columnstore Indexes                */
/*                   Creating Nonclustered B-Tree Index                     */
/****************************************************************************/

use SQLServerInternals
go


create nonclustered index IDX_Test_ID
on dbo.Test(ID);
go

-- Repeat UPDATE and DELETE tests and notice that blocking disappeared