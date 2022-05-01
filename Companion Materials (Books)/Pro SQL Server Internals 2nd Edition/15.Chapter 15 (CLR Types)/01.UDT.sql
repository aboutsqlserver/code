/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Chapter 15. CLR Types                            */
/*                                CLR UDT                                   */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*   That script uses objects created by "01.Object Creation.sql" script    */
/*                  from "14.Chapter 14 (CLR)" Chapter                      */
/****************************************************************************/
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'AddressesCLR') drop table dbo.AddressesCLR;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Addresses') drop table dbo.Addresses;
go

/*** CLR CODE ***/
/*
public struct USPostalAddress : INullable, IBinarySerialize
{
    // Needs to be sorted to support BinarySearch
    private static readonly List<string> _validStates = new List<string>
    {
        "AK","AL","AR","AZ","CA","CO","CT","DC","DE","FL","GA","HI","IA","ID","IL",
        "IN","KS","KY","LA","MA","MD","ME","MI","MN","MO","MS","MT","NC","ND","NE",
        "NH","NJ","NM","NV","NY","OH","OK","OR","PA","PR","RI","SC","SD","TN","TX",
        "UT","VA","VT","WA","WI","WV","WY"
    };

    private bool _null;
    private string _address;
    private string _city;
    private string _state;
    private string _zipCode;

    public bool IsNull { get { return _null; } }

    public string Address
    {
        [SqlMethod(IsDeterministic = true, IsPrecise = true)]
        get { return _address; }
    }

    public string City
    {
        [SqlMethod(IsDeterministic = true, IsPrecise = true)]
        get { return _city; }
    }

    public string State
    {
        [SqlMethod(IsDeterministic = true, IsPrecise=true)]
        get { return _state; }
    }

    public string ZipCode
    {
        [SqlMethod(IsDeterministic = true, IsPrecise = true)]
        get { return _zipCode; }
    }

    public override string ToString()
    {
        return String.Format("{0}, {1}, {2}, {3}", _address, _city, _state, _zipCode);
    }
    
    
    public static USPostalAddress Null
    {
        get
        {
            USPostalAddress h = new USPostalAddress();
            h._null = true;
            return h;
        }
    }

    private bool ValidateAddress()
    {
        // Check that all attributes are specified and state is valid
        return 
            !(
                String.IsNullOrEmpty(_address) ||
                String.IsNullOrEmpty(_city) ||
                String.IsNullOrEmpty(_state) ||
                String.IsNullOrEmpty(_zipCode) ||
                _validStates.BinarySearch(_state.ToUpper()) == -1
            );
    }
    
    public static USPostalAddress Parse(SqlString s)
    {
        if (s.IsNull)
            return Null;
        USPostalAddress u = new USPostalAddress();
        string[] parts = s.Value.Split(",".ToCharArray());
        if (parts.Length != 4)
            throw new ArgumentException("The value has incorrect format. Should be <Address>, <City>, <State>, <ZipCode>");
        u._address = parts[0].Trim();
        u._city = parts[1].Trim();
        u._state = parts[2].Trim();
        u._zipCode = parts[3].Trim();
        if (!u.ValidateAddress())
            throw new ArgumentException("The value has incorrect format. Attributes are empty or State is incorrect");
        return u;
    }


    [SqlMethod(OnNullCall = false, IsDeterministic = true, DataAccess=DataAccessKind.None)]
    public double CalculateShippingCost(USPostalAddress destination)
    {
        // Calculating shipping cost between two addresses
        if (destination.State == this.State)
            return 15.0;
        else
            return 25.0;
    }

    public void Read(System.IO.BinaryReader r)
    {
        _address = r.ReadString();
        _city = r.ReadString();
        _state = r.ReadString();
        _zipCode = r.ReadString();        
    }

    public void Write(System.IO.BinaryWriter w)
    {
        w.Write(_address);
        w.Write(_city);
        w.Write(_state);
        w.Write(_zipCode);
    }
}
*/

create table dbo.Addresses
(
	ID int not null identity(1,1),
	Address varchar(128) not null,
	City varchar(64) not null,
	State char(2) not null,
		constraint CHK_Address_State
		check (
			State in (
	'AK','AL','AR','AZ','CA','CO','CT','DC','DE','FL','GA','HI','IA'
	,'ID','IL','IN','KS','KY','LA','MA','MD','ME','MI','MN','MO','MS'
	,'MT','NC','ND','NE','NH','NJ','NM','NV','NY','OH','OK','OR','PA'
	,'PR','RI','SC','SD','TN','TX','UT','VA','VT','WA','WI','WV','WY'
			)
		),
	ZipCode varchar(10) not null,
	constraint PK_Addresses primary key clustered(ID)
);

create table dbo.AddressesCLR
(
	ID int not null identity(1,1),
	Address dbo.USPostalAddress not null,
	constraint PK_AddressesCLR primary key clustered(ID)
);

;with Streets(Street)
as
(
	/* select v.v 
	from (
		values('Street 1'),('Street 2'),('Street 3'),('Street 4')
		,('Street 5'), ('Street 6'),('Street 7'),('Street 8')
		,('Street 9'),('Street 10')
	) v(v) */
	select 'Street 1' union all select 'Street 2' union all select 'Street 3' union all 
	select'Street 4' union all select 'Street 5' union all select 'Street 6' union all 
	select'Street 7' union all select 'Street 8' union all select 'Street 9' union all 
	select'Street 10'
)
,Cities(City)
as
(
 	/* select v.v 
	from (
		values('City 1'),('City 2'),('City 3'),('City 4'),('City 5'),
	 		('City 6'),('City 7'),('City 8'),('City 9'),('City 10')
	) v(v) */
	select 'City 1' union all select 'City 2' union all select 'City 3' union all 
	select 'City 4' union all select 'City 5' union all select 'City 6' union all 
	select 'City 7' union all select 'City 8' union all select 'City 9' union all 
	select 'City 10'
)
,ZipCodes(Zip)
as
(
 	/* select v.v 
	from (
		values('99991'),('99992'),('99993'),('99994'),('99995'),
	 		('99996'),('99997'),('99998'),('99999'),('99990')
	 ) v(v) */
	select '99991' union all select '99992' union all select '99993' union all 
	select '99994' union all select '99995' union all select '99996' union all 
	select '99997' union all select '99998' union all select '99999' union all 
	select '99990'
)
,States(state)
as
(
 	/*select v.v 
	from (
	values('AL'),('AK'),('AZ'),('AR'),('CA'),('CO'),('CT'),('DE'),('FL'),
	('GA'),('HI'),('ID'),('IL'),('IN'),('IA'),('KS'),('KY'),('LA'),('ME'),
	('MD'),('MA'),('MI'),('MN'),('MS'),('MO'),('MT'),('NE'),('NV'),('NH'),
	('NJ'),('NM'),('NY'),('NC'),('ND'),('OH'),('OK'),('OR'),('PA'),('RI'),
	('SC'),('SD'),('TN'),('TX'),('UT'),('VT'),('VA'),('WA'),('WV'),('WI')
	,('WY'),('DC'),('PR')
	) v(v) */
	select 'AL' union all select 'AK' union all select 'AZ' union all select 'AR' union all 
	select 'CA' union all select 'CO' union all select 'CT' union all select 'DE' union all 
	select 'FL' union all select 'GA' union all select 'HI' union all select 'ID' union all 
	select 'IL' union all select 'IN' union all select 'IA' union all select 'KS' union all 
	select 'KY' union all select 'LA' union all select 'ME' union all select 'MD' union all 
	select 'MA' union all select 'MI' union all select 'MN' union all select 'MS' union all 
	select 'MO' union all select 'MT' union all select 'NE' union all select 'NV' union all 
	select 'NH' union all select 'NJ' union all select 'NM' union all select 'NY' union all 
	select 'NC' union all select 'ND' union all select 'OH' union all select 'OK' union all 
	select 'OR' union all select 'PA' union all select 'RI' union all select 'SC' union all 
	select 'SD' union all select 'TN' union all select 'TX' union all select 'UT' union all 
	select 'VT' union all select 'VA' union all select 'WA' union all select 'WV' union all 
	select 'WI' union all select 'WY' union all select 'DC' union all select 'PR'
)
insert into dbo.Addresses(Address,City,State,ZipCode)
 	select Street,City,State,Zip
	from Streets cross join Cities cross join States cross join ZipCodes;

insert into dbo.AddressesCLR(Address)
	select Address + ', ' + City + ', ' + State + ', ' + ZipCode
	from dbo.Addresses;
go


/*** UDT Usage ***/
declare
	@MicrosoftAddr dbo.USPostalAddress 
	,@GoogleAddr dbo.USPostalAddress

select
	@MicrosoftAddr = 'One Microsoft Way, Redmond, WA, 98052'
	,@GoogleAddr = '1600 Amphitheatre Pkwy, Mountain View, CA, 94043'

select
	@MicrosoftAddr as [Raw Data]
	,@MicrosoftAddr.ToString() as [Text Data]
	,@MicrosoftAddr.Address as [Address]
	,@MicrosoftAddr.CalculateShippingCost(@GoogleAddr) as [ShippingCost];
go


/*** Performance  ***/
set statistics time on

select State, count(*)
from dbo.Addresses
group by State;

select Address.State, count(*)
from dbo.AddressesCLR
group by Address.State;

set statistics time off
go

/*** Using persisted calculated columns ***/
alter table dbo.AddressesCLR add State as Address.State persisted;
go

-- Repuild the index to reduce the fragmentation caused by alteration
alter index PK_AddressesCLR on dbo.AddressesCLR rebuild;

create index IDX_AddressesCLR_State on dbo.AddressesCLR(State);
create index IDX_Addresses_State on dbo.Addresses(State);
go

set statistics time on

select State, count(*)
from dbo.Addresses
group by State;

select Address.State, count(*)
from dbo.AddressesCLR
group by Address.State;

set statistics time off
go

