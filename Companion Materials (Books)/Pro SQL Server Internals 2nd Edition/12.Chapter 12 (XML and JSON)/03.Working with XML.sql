/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                             Chapter 12. XML                              */
/*                          Working with XML Data                           */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*       This script uses the objects created in the previous scripts       */
/****************************************************************************/


/*** Singleton Example ***/

declare
	@X xml 

select @X = 
N'<Order OrderId="42" OrderTotal="49.96">
  <Customer Id="123"/>
  <OrderLineItems>
    <OrderLineItem>
      <ArticleId>250</ArticleId>
      <Quantity>3</Quantity>
      <Price>9.99</Price>
    </OrderLineItem>
  </OrderLineItems>
</Order>';

-- SUCCESS: Get @Id from the first customer from first order
select @X.value('/Order[1]/Customer[1]/@Id','int');

-- SUCCESS: Get first ArticleId from the first order from the first line item
select @X.value('/Order[1]/OrderLineItems[1]/OrderLineItem[1]/ArticleId[1]','int');

-- ERROR: Not a singleton - SQL Server does not know that ArticleId is the element rather than section
--select @X.value('/Order[1]/OrderLineItems[1]/OrderLineItem[1]/ArticleId','int');

-- ERROR: Not a singleton - XML can include the information about multiple orders and/or customers
--select @X.value('/Order/Customer/@Id','int');
go


-- Enable "Include Actual Execution Plan"
-- Compare Execution Plans of various approaches

/*** Atomization of Nodes ***/
declare
	@X xml 

select @X = 
'<Order OrderId="42" OrderTotal="49.96">
  <CustomerId>123</CustomerId>
  <OrderNum>10025</OrderNum>
  <OrderDate>2016-07-15T10:05:20</OrderDate>
  <OrderLineItems>
    <OrderLineItem>
      <ArticleId>250</ArticleId>
      <Quantity>3</Quantity>
      <Price>9.99</Price>
    </OrderLineItem>
    <OrderLineItem>
      <ArticleId>404</ArticleId>
      <Quantity>1</Quantity>
      <Price>19.99</Price>
    </OrderLineItem>
  </OrderLineItems>
</Order>';

select @X.value('(/Order/CustomerId)[1]','int');
select @X.value('(/Order/CustomerId/text())[1]','int');
go

declare
	@X xml (document ElementCentricSchema)

select @X = 
'<Order>
  <OrderId>42</OrderId>
  <OrderTotal>49.96</OrderTotal>	
  <CustomerId>123</CustomerId>
  <OrderNum>10025</OrderNum>
  <OrderDate>2016-07-15T10:05:20Z</OrderDate>
  <OrderLineItems>
    <OrderLineItem>
      <ArticleId>250</ArticleId>
      <Quantity>3</Quantity>
      <Price>9.99</Price>
    </OrderLineItem>
    <OrderLineItem>
      <ArticleId>404</ArticleId>
      <Quantity>1</Quantity>
      <Price>19.99</Price>
    </OrderLineItem>
  </OrderLineItems>
</Order>';

select @X.value('(/Order/CustomerId)[1]','int');
go


/*** Using Primary XML Index ***/
select XmlData.value('(/Order/CustomerId)[1]','int')
from dbo.ElementCentricTyped
where ID = 1;
go


/*** exist() vs value() ***/
if not exists
(
	select * 
	from 
		sys.indexes i join sys.tables t on
			i.object_id = t.object_id
		join sys.schemas s on
			t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'ElementCentricUntyped' and i.name = 'XML_Value'
)
	create xml index XML_Value on dbo.ElementCentricUntyped(XMLData)
	using xml index XML_Primary_ElementCentricUntyped for value;
go

select count(*) 
from dbo.ElementCentricUntyped
where XmlData.exist('/Order/OrderNum/text()[.="10025"]') = 1;

select count(*) 
from dbo.ElementCentricUntyped
where XmlData.value('(/Order/OrderNum/text())[1]','varchar(32)') = '10025';
go

/*** String Comparison is case- and accent-sensetive ***/
declare
	@X xml 
	,@V varchar(32)

select 
	@X = '<Order OrderNum="Order1"><OrderId>1</OrderId></Order>'
	,@V = 'ORDER1';

select 'exist(): found' as [Result]
where @X.exist('/Order/@OrderNum[.=sql:variable("@V")]') = 1;

select 'value(): found' as [Result]
where @X.value('/Order[1]/@OrderNum','varchar(16)') = @V;
go

/*** Atomization of Nodes and Type Casting ***/
declare
	@X xml 

select @X = '<Order OrderNum="Order1"><OrderId>1</OrderId></Order>';

select 'Atomization of nodes'
where @X.exist('/Order[OrderId=1]') = 1;

select 'No text() function'
where @X.exist('/Order/OrderId[.=1]') = 1;

select 'With text() function'
where @X.exist('/Order/OrderId/text()[.=1]') = 1;
go

/*** XML Transformation with Query() method ***/
declare
	@X xml 

select @X = 
'<Order OrderId="42" OrderTotal="49.96">
	<CustomerId>123</CustomerId>
	<OrderNum>10025</OrderNum>
</Order>';

select
	@X.query('/Order/CustomerId') as [Part of XML]
	,@X.query('<Customer Id="{/Order/CustomerId/text()}"/>') as [Transform];
go


/*** Nodes() Method Demos ***/
declare
	@X xml 

select @X =
'<Order OrderId="42" OrderTotal="49.96">
  <CustomerId>123</CustomerId>
  <OrderNum>10025</OrderNum>
  <OrderDate>2016-07-15T10:05:20Z</OrderDate>
  <OrderLineItems>
    <OrderLineItem>
      <ArticleId>250</ArticleId>
      <Quantity>3</Quantity>
      <Price>9.99</Price>
    </OrderLineItem>
    <OrderLineItem>
      <ArticleId>404</ArticleId>
      <Quantity>1</Quantity>
      <Price>19.99</Price>
    </OrderLineItem>
  </OrderLineItems>
</Order>';

select
	t.c.query('.') as [Raw Node]
	,t.c.value('(ArticleId/text())[1]','int') as [ArticleId] 
from @X.nodes('/Order/OrderLineItems/OrderLineItem') as t(c);
go

select 
	t.ID
	,sum(Items.Item.value('(Quantity/text())[1]','int') * 
			Items.Item.value('(Price/text())[1]','float')) as [Total]
from 
	dbo.ElementCentricUntyped t cross apply
		t.XMLData.nodes('/Order/OrderLineItems/OrderLineItem') 
				as Items(Item)   
group by 
	t.ID;
go

/*** Nodes() method: Drill-Down Approach ***/
declare
	@X xml

select @X =
N'<Orders>
	<Order OrderId="42" CustomerId="123" OrderNum="10025">
		<OrderLineItem ArticleId="250" Quantity="3" Price="9.99"/>
		<OrderLineItem ArticleId="404" Quantity="1" Price="19.99"/>
	</Order>
	<Order OrderId="54" CustomerId="234" OrderNum="10025">
		<OrderLineItem ArticleId="15" Quantity="1" Price="14.99"/>
		<OrderLineItem ArticleId="121" Quantity="2" Price="6.99"/>
	</Order>
</Orders>';

select
	LineItems.Item.value('../@OrderId','int') as [OrderId]
	,LineItems.Item.value('../@OrderNum','varchar(32)') as [OrderNum]
	,LineItems.Item.value('@ArticleId','int') as [ArticleId] 
	,LineItems.Item.value('@Quantity','int') as [Quantity] 
	,LineItems.Item.value('@Price','float') as [Price] 
from
	@X.nodes('/Orders/Order/OrderLineItem') as LineItems(Item);


select
	Orders.Ord.value('@OrderId','int') as [OrderId]
	,Orders.Ord.value('@OrderNum','varchar(32)') as [CustomerId]
	,LineItems.Item.value('@ArticleId','int') as [ArticleId] 
	,LineItems.Item.value('@Quantity','int') as [Quantity] 
	,LineItems.Item.value('@Price','float') as [Price] 
from
	@X.nodes('/Orders/Order') as Orders(Ord) cross apply
		Orders.Ord.nodes('OrderLineItem') as LineItems(Item);
go

/*** FOR XML PATH Demo ***/
declare
	@Orders table
	(
		OrderId int not null primary key,
		CustomerId int not null,
		OrderNum varchar(32) not null,
		OrderDate datetime not null
	)

declare
	@OrderLineItems table
	(
		OrderId int not null,
		ArticleId int not null,
		Quantity int not null,
		Price float not null,
		primary key(OrderId, ArticleId)
	)

insert into @Orders(OrderId, CustomerId, OrderNum, OrderDate)
values (42,123,'10025','2016-07-15T10:05:20');
insert into @Orders(OrderId, CustomerId, OrderNum, OrderDate)
values (54,25,'10032','2016-07-15T11:21:00');

insert into @OrderLineItems(OrderId, ArticleId, Quantity, Price)
values(42,250,3,9.99);
insert into @OrderLineItems(OrderId, ArticleId, Quantity, Price)
values(42,404,1,19.99);
insert into @OrderLineItems(OrderId, ArticleId, Quantity, Price)
values(54,15,1,14.99);
insert into @OrderLineItems(OrderId, ArticleId, Quantity, Price)
values(54,121,2,6.99);

select
	o.OrderId as [@OrderId]
	,o.OrderNum as [OrderNum]
	,o.CustomerId as [CustomerId] 
	,o.OrderDate as [OrderDate]
	,(
		select
			i.ArticleId as [@ArticleId]
			,i.Quantity as [@Quantity]
			,i.Price as [@Price]
		from @OrderLineItems i
		where i.OrderId = o.OrderId
		for xml path('OrderLineItem'),root('OrderLineItems'), type
	)
from @Orders o
for xml path('Order'),root('Orders');
go






