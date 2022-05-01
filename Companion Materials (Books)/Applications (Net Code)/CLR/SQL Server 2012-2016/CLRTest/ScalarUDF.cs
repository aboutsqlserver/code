/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapters 14 and 15. CLR and CLR Types                  */
/*                           User-defined functions                         */
/****************************************************************************/
using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Collections;

public partial class UserDefinedFunctions
{
    [Microsoft.SqlServer.Server.SqlFunction(
        IsDeterministic=true,
        IsPrecise=true,
        DataAccess = DataAccessKind.Read)]
    public static SqlInt32 EvenNumberCLR(SqlInt32 id)
    {
        return new SqlInt32((id % 2 == 0)?1:0);
    }

    [Microsoft.SqlServer.Server.SqlFunction(
        IsDeterministic=true,
        IsPrecise=true,
        DataAccess=DataAccessKind.Read)]
    public static SqlInt32 EvenNumberCLRWithDataAccess(SqlInt32 id)
    {
        return new SqlInt32((id % 2 == 0) ? 1 : 0);
    }

    [Microsoft.SqlServer.Server.SqlFunction(
        IsDeterministic = true, 
        IsPrecise = false, 
        DataAccess = DataAccessKind.None)]
    public static SqlDouble CalcDistanceCLR(
        SqlDouble fromLat,
        SqlDouble fromLon,
        SqlDouble toLat,
        SqlDouble toLon)
    {
        double fromLatR =  Math.PI / 180 * fromLat.Value;
        double fromLonR = Math.PI / 180 * fromLon.Value;
        double toLatR = Math.PI / 180 * toLat.Value;
        double toLonR = Math.PI / 180 * toLon.Value;
        return new SqlDouble( 2 * Math.Asin(
				Math.Sqrt(
					Math.Pow(Math.Sin((fromLatR - toLatR) / 2.0),2) +
					(
						Math.Cos(fromLatR) * Math.Cos(toLatR) * 
                            Math.Pow(Math.Sin((fromLonR - toLonR) / 2.0),2)
					)
				)
			) * 20001600.0 / Math.PI);
    }

    private struct BoundingBox
    {
        public double minLat;
        public double maxLat;
        public double minLon;
        public double maxLon;
    }

    private static void CircleBoundingBox_FillValues(
        object obj, out SqlDouble MinLat, out SqlDouble MaxLat,
        out SqlDouble MinLon, out SqlDouble MaxLon)
    {
        BoundingBox box = (BoundingBox)obj;
        MinLat = new SqlDouble(box.minLat);
        MaxLat = new SqlDouble(box.maxLat);
        MinLon = new SqlDouble(box.minLon);
        MaxLon = new SqlDouble(box.maxLon);
    }


    [Microsoft.SqlServer.Server.SqlFunction(
        DataAccess = DataAccessKind.None,
        IsDeterministic = true, IsPrecise = false,
        FillRowMethodName = "CircleBoundingBox_FillValues",
        TableDefinition = "MinLat float, MaxLat float, MinLon float, MaxLon float")]
    public static IEnumerable CalcCircleBoundingBox(SqlDouble lat, SqlDouble lon, SqlInt32 distance)
    {
        if (lat.IsNull || lon.IsNull || distance.IsNull)
            return null;

        BoundingBox[] box = new BoundingBox[1];

        double latR = Math.PI / 180 * lat.Value;
        double lonR = Math.PI / 180 * lon.Value;
        double rad45 = 0.785398163397448300;  // RADIANS(45.)
        double rad135 = 2.356194490192344800; // RADIANS(135.)
        double rad225 = 3.926990816987241400; // RADIANS(225.)
        double rad315 = 5.497787143782137900; // RADIANS(315.) 
        double distR = distance.Value * 1.4142135623731 * Math.PI / 20001600.0;

        double latR45 = Math.Asin(Math.Sin(latR) * Math.Cos(distR) +
                Math.Cos(latR) * Math.Sin(distR) * Math.Cos(rad45));
        double latR135 = Math.Asin(Math.Sin(latR) * Math.Cos(distR) +
                Math.Cos(latR) * Math.Sin(distR) * Math.Cos(rad135));
        double latR225 = Math.Asin(Math.Sin(latR) * Math.Cos(distR) +
                Math.Cos(latR) * Math.Sin(distR) * Math.Cos(rad225));
        double latR315 = Math.Asin(Math.Sin(latR) * Math.Cos(distR) +
                Math.Cos(latR) * Math.Sin(distR) * Math.Cos(rad315));

        double dLonR45 = Math.Atan2(Math.Sin(rad45) * Math.Sin(distR) * Math.Cos(latR),
                Math.Cos(distR) - Math.Sin(latR) * Math.Sin(latR45));
        double dLonR135 = Math.Atan2(Math.Sin(rad135) * Math.Sin(distR) * Math.Cos(latR),
                Math.Cos(distR) - Math.Sin(latR) * Math.Sin(latR135));
        double dLonR225 = Math.Atan2(Math.Sin(rad225) * Math.Sin(distR) * Math.Cos(latR),
                Math.Cos(distR) - Math.Sin(latR) * Math.Sin(latR225));
        double dLonR315 = Math.Atan2(Math.Sin(rad315) * Math.Sin(distR) * Math.Cos(latR),
                Math.Cos(distR) - Math.Sin(latR) * Math.Sin(latR315));

        double lat45 = latR45 * 180.0 / Math.PI;
        double lat225 = latR225 * 180.0 / Math.PI;
        double lon45 = (((lonR - dLonR45 + Math.PI) % (2 * Math.PI)) - Math.PI) *
                180.0 / Math.PI;
        double lon135 = (((lonR - dLonR135 + Math.PI) % (2 * Math.PI)) - Math.PI) *
                180.0 / Math.PI;
        double lon225 = (((lonR - dLonR225 + Math.PI) % (2 * Math.PI)) - Math.PI) *
                180.0 / Math.PI;
        double lon315 = (((lonR - dLonR315 + Math.PI) % (2 * Math.PI)) - Math.PI) *
                180.0 / Math.PI;

        box[0].minLat = Math.Min(lat45, lat225);
        box[0].maxLat = Math.Max(lat45, lat225);
        box[0].minLon = Math.Min(Math.Min(lon45, lon135), Math.Min(lon225, lon315));
        box[0].maxLon = Math.Max(Math.Max(lon45, lon135), Math.Max(lon225, lon315));

        return box;
    }

}
