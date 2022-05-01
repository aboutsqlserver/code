/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapters 14 and 15. CLR and CLR Types                  */
/*                                  CLR UDT                                 */
/****************************************************************************/
using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Collections.Generic;

[Serializable]
[Microsoft.SqlServer.Server.SqlUserDefinedType(
    Format.UserDefined, 
    ValidationMethodName = "ValidateAddress",
    MaxByteSize=8000
)]
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