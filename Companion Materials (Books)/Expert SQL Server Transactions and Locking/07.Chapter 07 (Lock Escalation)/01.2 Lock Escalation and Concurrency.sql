/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 07. Lock Escalation				            */
/*          Disabled Lock Escalation and Concurrency (Session 2)            */
/****************************************************************************/

use SQLServerInternals
go

insert into Delivery.Orders(OrderDate,OrderNum, CustomerId, PickupAddressId
		,DeliveryAddressId, ServiceId, RatePlanId, OrderStatusId, Pieces, Amount)
values('2018-06-01T08:00:00', '123456', 1, 1, 3, 1, 1, 1, 2, 25);