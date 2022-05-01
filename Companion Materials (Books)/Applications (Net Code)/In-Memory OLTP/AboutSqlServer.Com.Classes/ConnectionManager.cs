/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                             Common Classes                               */
/****************************************************************************/

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;
using System.Data.SqlClient;

namespace AboutSqlServer.Com.Classes
{
    public class ConnectionManager
    {
        public ConnectionManager(string connStrName)
        {
            if (!String.IsNullOrEmpty(connStrName) && ConfigurationManager.ConnectionStrings[connStrName] != null)
                _connStr = ConfigurationManager.ConnectionStrings[connStrName].ConnectionString;
        }

        public SqlConnection GetConnection()
        {
            SqlConnection conn = GetSqlConnection();
            conn.Open();
            return conn;
        }

        public bool ValidateConnection(out string connError)
        {
            using (SqlConnection conn = GetSqlConnection())
            {
                try
                {
                    conn.Open();
                    conn.Close();
                    connError = null;
                    return true;
                }
                catch (Exception ex)
                {
                    connError = ex.Message;
                    return false;
                }
            }
        }

        private SqlConnection GetSqlConnection()
        {
            if (String.IsNullOrEmpty(_connStr))
                throw new Exception("ConnectionManager::GetSqlConnection() - Connection string has not been specified");
            return new SqlConnection( _connStr);
        }

        public string ConnStr 
        { 
            get { return _connStr; }
            set
            {
                if (String.IsNullOrEmpty(value))
                    throw new Exception("ConnectionManager::SetConnStr() - Connection String is Empty");
                _connStr = value;
            }
        }

        private string _connStr = null;
    }
}
