/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*              Chapter 12. Troubleshooting Concurrency Issues              */
/*                    Readable Secondaries (Session 1)                      */
/****************************************************************************/

-- Run on readable secondary node!!

use SQLServerInternals
go

begin tran
    select * from dbo.T2;
