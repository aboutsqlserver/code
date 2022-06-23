/****************************************************************************/
/*                        Intro into Index Analysis                         */
/*																			*/
/*                         Dmitri V. Korotkevitch                           */
/*                        http://aboutsqlserver.com                         */
/*                          dk@aboutsqlserver.com                           */
/****************************************************************************/
/*					              NCI Usage                                 */
/****************************************************************************/

use SQLServerInternals
go

set statistics io on
go

select count(*)
from dbo.Orders with (index = 1)
go

select * 
from dbo.Orders
where OrderSeq between 1 and 1000;
go

select * 
from dbo.Orders
where OrderSeq between 1 and 10000;
go

select * 
from dbo.Orders
where OrderSeq between 1 and 20000;
go

select * 
from dbo.Orders with (index = IDX_Orders_OrderSeq)
where OrderSeq between 1 and 20000;
go

select 20000. / count(*) * 100
from dbo.Orders;
go


