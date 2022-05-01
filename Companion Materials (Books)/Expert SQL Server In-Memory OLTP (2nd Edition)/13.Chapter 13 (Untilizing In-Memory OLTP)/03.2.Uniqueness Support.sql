/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*                  03.Enforcing Uniqueness (Session 2)                     */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go


declare
	@ProductId int

exec dbo.InsertProduct
	'Expert SQL Server In-Memory OLTP'
	,'Published by APress'
	,@ProductId output;
