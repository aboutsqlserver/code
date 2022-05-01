/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                             Chapter 12. XML                              */
/*                            XML Storage Space                             */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'ElementCentricUntyped') drop table dbo.ElementCentricUntyped;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'ElementCentricTyped') drop table dbo.ElementCentricTyped;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'AttributeCentricUntyped') drop table dbo.AttributeCentricUntyped;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'AttributeCentricTyped') drop table dbo.AttributeCentricTyped;
if exists(select * from sys.xml_schema_collections c join sys.schemas s on c.schema_id = s.schema_id where s.name = 'dbo' and c.name = 'ElementCentricSchema') drop xml schema collection dbo.ElementCentricSchema;
if exists(select * from sys.xml_schema_collections c join sys.schemas s on c.schema_id = s.schema_id where s.name = 'dbo' and c.name = 'AttributeCentricSchema') drop xml schema collection dbo.AttributeCentricSchema;
go

create xml schema collection ElementCentricSchema as
'<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Order">
    <xs:complexType>
      <xs:sequence>
        <xs:element type="xs:int" name="OrderId"/>
        <xs:element type="xs:float" name="OrderTotal"/>
        <xs:element type="xs:int" name="CustomerId"/>
        <xs:element type="xs:string" name="OrderNum"/>
        <xs:element type="xs:dateTime" name="OrderDate"/>
        <xs:element name="OrderLineItems">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="OrderLineItem" maxOccurs="unbounded" minOccurs="0">
                <xs:complexType>
                  <xs:sequence>
                    <xs:element type="xs:int" name="ArticleId"/>
                    <xs:element type="xs:int" name="Quantity"/>
                    <xs:element type="xs:float" name="Price"/>
                  </xs:sequence>
                </xs:complexType>
              </xs:element>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>';

create xml schema collection AttributeCentricSchema as
'<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Order">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="OrderLineItem" maxOccurs="unbounded" minOccurs="0">
          <xs:complexType>
            <xs:simpleContent>
              <xs:extension base="xs:string">
                <xs:attribute type="xs:int" name="ArticleId" use="optional"/>
                <xs:attribute type="xs:int" name="Quantity" use="optional"/>
                <xs:attribute type="xs:float" name="Price" use="optional"/>
              </xs:extension>
            </xs:simpleContent>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
      <xs:attribute type="xs:int" name="OrderId"/>
      <xs:attribute type="xs:float" name="OrderTotal"/>
      <xs:attribute type="xs:int" name="CustomerId"/>
      <xs:attribute type="xs:string" name="OrderNum"/>
      <xs:attribute type="xs:dateTime" name="OrderDate"/>
    </xs:complexType>
  </xs:element>
</xs:schema>';
go

create table dbo.ElementCentricUntyped
(
	ID int not null identity(1,1),
	XMLData xml not null,
	constraint PK_ElementCentricUntyped
	primary key clustered(ID) 
);

create table dbo.ElementCentricTyped
(
	ID int not null identity(1,1),
	XMLData xml (document ElementCentricSchema) not null,
	constraint PK_ElementCentricTyped
	primary key clustered(ID) 
);

create table dbo.AttributeCentricUntyped
(
	ID int not null identity(1,1),
	XMLData xml not null,
	constraint PK_AttributeCentricUntyped
	primary key clustered(ID) 
);

create table dbo.AttributeCentricTyped
(
	ID int not null identity(1,1),
	XMLData xml (document AttributeCentricSchema) not null,
	constraint PK_AttributeCentricTyped
	primary key clustered(ID) 
);
go

-- SQL Server 2005 requires to add 'Z' at the end of datetime value
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.ElementCentricUntyped(XMLData)
select '
<Order>
  <OrderId>42</OrderId>
  <OrderTotal>49.96</OrderTotal>	
  <CustomerId>123</CustomerId>
  <OrderNum>10025</OrderNum>
  <OrderDate>2013-07-15T10:05:20Z</OrderDate>
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
</Order>'
from Ids;

insert into dbo.ElementCentricTyped(XMLData)
	select XMLData from dbo.ElementCentricUntyped;

-- SQL Server 2005 requires to add 'Z' at the end of datetime value
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.AttributeCentricUntyped(XMLData)
select 
N'<Order OrderId="42" OrderTotal="49.96" CustomerId="123" 
		OrderNum="10025" OrderDate="2013-07-15T10:05:20Z">
  <OrderLineItem ArticleId="250" Quantity="3" Price="9.99"/>
  <OrderLineItem ArticleId="404" Quantity="1" Price="19.99"/>
</Order>'
from Ids;

insert into dbo.AttributeCentricTyped(XMLData)
	select XMLData from dbo.AttributeCentricUntyped;
go

create primary xml index XML_Primary_ElementCentricUntyped
on dbo.ElementCentricUntyped(XMLData);

create primary xml index XML_Primary_ElementCentricTyped
on dbo.ElementCentricTyped(XMLData);

create primary xml index XML_Primary_AttributeCentricUntyped
on dbo.AttributeCentricUntyped(XMLData);

create primary xml index XML_Primary_AttributeCentricTyped
on dbo.AttributeCentricTyped(XMLData);
go

select 
	db.name as "db_name", o.name as "tab_name", i.name as "idx_name"
    ,st.index_type_desc, st.alloc_unit_type_desc
    ,sum(st.record_count* st.avg_record_size_in_bytes) / 1024. as "size_in_bytes"
    ,sum(st.fragment_count) as "fragment_count", sum(st.page_count) as "page_count"
from 
	sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL , 'DETAILED') st
		join sys.databases db on db.database_id=st.database_id
		left outer join sys.objects o on o.object_id = st.object_id
		left outer join sys.indexes i on i.object_id = st.object_id and i.index_id = st.index_id
where
	o.object_id in 
	(
		object_id(N'dbo.ElementCentricUntyped'),object_id(N'dbo.ElementCentricTyped')
		,object_id(N'dbo.AttributeCentricUntyped'),object_id(N'dbo.AttributeCentricTyped')
	)
group by 
	db.name, o.name, i.name, st.index_type_desc, st.alloc_unit_type_desc
order by 
	db.name, o.name, st.index_type_desc;
