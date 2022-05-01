/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                             Chapter 12. XML                              */
/*                            Primary XML Index                             */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'XmlDemo') drop table dbo.XmlDemo;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'XmlTypedDemo') drop table dbo.XmlTypedDemo;
if exists(select * from sys.xml_schema_collections c join sys.schemas s on c.schema_id = s.schema_id where s.name = 'dbo' and c.name = 'XmlDemoCollection') drop xml schema collection dbo.XmlDemoCollection;
go

create table dbo.XmlDemo
(
	ID int not null identity(1,1),
	XMLData xml not null,

	constraint PK_XmlDemo
	primary key clustered(ID)
);
go

create xml schema collection XmlDemoCollection as
N'<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Order">
    <xs:complexType>
      <xs:sequence>
        <xs:element type="xs:int" name="CustomerId"/>
        <xs:element type="xs:string" name="OrderNum"/>
        <xs:element type="xs:dateTime" name="OrderDate"/>
        <xs:element name="OrderLineItems">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="OrderLineItem" maxOccurs="unbounded" minOccurs="0">
                <xs:complexType>
                  <xs:sequence>
                    <xs:element type="xs:short" name="ArticleId"/>
                    <xs:element type="xs:int" name="Quantity"/>
                    <xs:element type="xs:float" name="Price"/>
                  </xs:sequence>
                </xs:complexType>
              </xs:element>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
      <xs:attribute type="xs:int" name="OrderId"/>
      <xs:attribute type="xs:float" name="OrderTotal"/>
    </xs:complexType>
  </xs:element>
</xs:schema>';
go

create table dbo.XmlTypedDemo
(
	ID int not null identity(1,1),
	XMLData xml (document xmldemocollection) not null,

	constraint PK_XmlTypedDemo
	primary key clustered(ID)
)
go

declare
	@X xml 

-- SQL Server 2005 requires to add 'Z' at the end of datetime value
select @X = N'<Order OrderId="42" OrderTotal="49.96">
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
</Order>';

insert into dbo.XMLDemo(XMLData) values(@X);
insert into dbo.XmlTypedDemo(XMLData) values(@X);
go

create primary xml index XML_Primary_XmlTypedDemo
on dbo.XmlTypedDemo(XMLData);
go

create primary xml index XML_Primary_XmlDemo
on dbo.XmlDemo(XMLData);
go

select object_name(parent_object_id) as [Table], * 
from sys.internal_tables
where parent_object_id in 
	(
		object_id(N'dbo.XMLDemo'), object_id(N'dbo.XMLTypedDemo')
	);
go

/** THE CODE BELOW WORKS ONLY UNDER DEDICATED ADMIN CONNECTION **/
declare
	@Name sysname
	,@SQL nvarchar(max)

set @Name = 
	(
		select Name 
		from sys.internal_tables
		where parent_object_id = object_id(N'dbo.XMLDemo')
	);

select @SQL = N'select * from sys.' + @Name;
exec sp_executesql @SQL;
go

declare
	@Name sysname
	,@SQL nvarchar(max)

set @Name = 
	(
		select Name 
		from sys.internal_tables
		where parent_object_id = object_id(N'dbo.XMLTypedDemo')
	);

select @SQL = N'select * from sys.' + @Name;
exec sp_executesql @SQL;
go

