/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                   Chapters 14 and 15. CLR and CLR Types                  */
/*                             CLR Procedures                               */
/****************************************************************************/
using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void ExistInIntervalCLR(
        SqlInt32 minId, 
        SqlInt32 maxId, 
        out SqlInt32 rowCnt)
    {
        int result = 0;
        using (SqlConnection conn = new SqlConnection("context connection=true"))
        {
            conn.Open();
            SqlCommand cmd = new SqlCommand(
            @"select @Result = 
                case 
                    when exists(select * from dbo.Numbers where Num=@Number) 
                    then 1 
                    else 0 
                end", conn);
            cmd.Parameters.Add("@Result", SqlDbType.Int).Direction = 
                    ParameterDirection.Output;
            cmd.Parameters.Add("@Number", SqlDbType.Int);
            for (int i = minId.Value; i <= maxId.Value; i++)
            {
                cmd.Parameters[1].Value = i;
                cmd.ExecuteNonQuery();
                result += (int)cmd.Parameters[0].Value;
                System.Threading.Thread.Sleep(0);
            }
        }
        rowCnt = new SqlInt32(result);
    }

    
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void ExistInIntervalReaderCLR(
        SqlInt32 minId, 
        SqlInt32 maxId, 
        out SqlInt32 rowCnt)
    {
        int result = 0;
        using (SqlConnection conn = new SqlConnection("context connection=true"))
        {
            conn.Open();
            SqlCommand cmd = new SqlCommand(
            @"select Num 
            from dbo.Numbers 
            where Num between @MinId and @MaxId", conn);
            cmd.Parameters.Add("@MinId", SqlDbType.Int).Value = minId;
            cmd.Parameters.Add("@MaxId", SqlDbType.Int).Value = maxId;
            using (SqlDataReader reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    result++;
                    if (result % 500 == 0)
                        System.Threading.Thread.Sleep(0);
                }
            }         
        }
        rowCnt = new SqlInt32(result);
    }


    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void EndlessLoop()
    {
        while (1 == 1) ;
    }

}
