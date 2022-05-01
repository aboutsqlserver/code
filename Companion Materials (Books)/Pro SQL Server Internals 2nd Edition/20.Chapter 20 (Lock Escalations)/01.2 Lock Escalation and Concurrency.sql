/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 20. Lock Escalations				            */
/*          Disabled Lock Escalation and Concurrency (Session 2)            */
/****************************************************************************/

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses the objects created in "01.DB Creation.sql" script      */
/*                          from 00.Init project                            */
/****************************************************************************/

insert into Delivery.Orders(OrderDate,OrderNum, CustomerId, PickupAddressId
		,DeliveryAddressId, ServiceId, RatePlanId, OrderStatusId, Pieces, Amount)
values('2016-06-01T08:00:00', '123456', 1, 1, 3, 1, 1, 1, 2, 25);