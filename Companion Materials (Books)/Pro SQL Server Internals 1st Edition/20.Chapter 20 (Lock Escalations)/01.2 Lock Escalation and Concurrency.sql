/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                     Chapter 20. Lock Escalations				            */
/*          Disabled Lock Escalation and Concurrency (Session 2)            */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/* That script uses objects created by "02.Part 5 Objects.sql" script from  */
/*                             00.Init project                              */
/****************************************************************************/

insert into Delivery.Orders(OrderDate,OrderNum, CustomerId, PickupAddressId
		,DeliveryAddressId, ServiceId, RatePlanId, OrderStatusId, Pieces, Amount)
values('2013-06-01T08:00:00', '123456', 1, 1, 3, 1, 1, 1, 2, 25)