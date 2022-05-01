/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                                 Testing                                  */
/*                    Testing Blocking Event Notification                   */
/*                               (Session 2)                                */
/****************************************************************************/

use tempdb
go

-- Session 2 code
select count(*)
from tempdb.dbo.Data with (readcommitted);
go
