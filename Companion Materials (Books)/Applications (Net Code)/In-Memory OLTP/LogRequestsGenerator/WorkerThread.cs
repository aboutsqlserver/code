/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 2 - Log Requests Generation Utility                */
/****************************************************************************/

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using System.Data.SqlClient;
using System.Data;
using AboutSqlServer.Com.Classes;

namespace Actsoft.Com.LogRequestsGenerator
{
    public  class WorkerThread : BaseThread
    {
        public WorkerThread(ConnectionManager connManager, string spName) : base(0) 
        {
            this._connManager = connManager;
            this._spName = spName;
        }

        protected override IDisposable GetExecuteDisposable()
        {
            _conn = _connManager.GetConnection();
            return _conn;
        }

        protected override void OnExecute()
        {
            base.OnExecute();
            _cmd = CreateCommand();
            _cmd.Connection = _conn;
        }

        private SqlCommand CreateCommand()
        {
            SqlCommand cmd = new SqlCommand(_spName);
            cmd.CommandType = System.Data.CommandType.StoredProcedure;
            cmd.Parameters.Add("@URL",SqlDbType.VarChar,255).Value = "http://mywebsite.com/OneOfAppURL";
            cmd.Parameters.Add("@RequestType",SqlDbType.TinyInt).Value = 1;
            cmd.Parameters.Add("@ClientIP",SqlDbType.VarChar,15);
            cmd.Parameters.Add("@BytesReceived",SqlDbType.Int);
            cmd.Parameters.Add("@Authorization", SqlDbType.VarChar, 256).Value = "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==";
            cmd.Parameters.Add("@UserAgent",SqlDbType.VarChar,256).Value = "Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/21.0";
            cmd.Parameters.Add("@Host",SqlDbType.VarChar,256).Value = "www.mywebsite.com";
            cmd.Parameters.Add("@Connection",SqlDbType.VarChar,256).Value = "Upgrade";
            cmd.Parameters.Add("@Referer", SqlDbType.VarChar, 256).Value = "http://mywebsite.com/AnotherURL";
            cmd.Parameters.Add("@Param1",SqlDbType.VarChar,64).Value = "AccountID";
            cmd.Parameters.Add("@Param1Value",SqlDbType.NVarChar,256).Value = "123456";
            cmd.Parameters.Add("@Param2",SqlDbType.VarChar,64).Value = "UserID";
            cmd.Parameters.Add("@Param2Value",SqlDbType.NVarChar,256);
            cmd.Parameters.Add("@Param3",SqlDbType.VarChar,64).Value = "StartTime";
            cmd.Parameters.Add("@Param3Value",SqlDbType.NVarChar,256);
            cmd.Parameters.Add("@Param4",SqlDbType.VarChar,64).Value = "StopTime";;
            cmd.Parameters.Add("@Param4Value",SqlDbType.NVarChar,256);
            cmd.Parameters.Add("@Param5",SqlDbType.VarChar,64).Value = "Sort";;
            cmd.Parameters.Add("@Param5Value",SqlDbType.NVarChar,256);
            return cmd;
        }

        protected sealed override void DoIteration()
        {
            _cmd.Parameters[2].Value = String.Format("{0}.{1}.{2}.{3}", DateTime.Now.Millisecond % 254 + 1, DateTime.Now.Millisecond % 254, _iteration % 254, _iteration % 999);
            _cmd.Parameters[3].Value = 1000 * (_iteration % 4 + 1);
            switch (_iteration % 5)
            {
                case 0: _cmd.Parameters[12].Value = _cmd.Parameters[14].Value = _cmd.Parameters[16].Value = _cmd.Parameters[18].Value = DBNull.Value; break;
                case 1: _cmd.Parameters[12].Value = "23456";
                    _cmd.Parameters[14].Value = _cmd.Parameters[16].Value = _cmd.Parameters[18].Value = DBNull.Value; break;
                case 2: _cmd.Parameters[12].Value = "4567";
                    _cmd.Parameters[14].Value = "2015-01-01T10:00:00";
                    _cmd.Parameters[16].Value = _cmd.Parameters[18].Value = DBNull.Value; break;
                case 3: _cmd.Parameters[12].Value = "4567";
                    _cmd.Parameters[14].Value = "2015-01-01T10:00:00";
                    _cmd.Parameters[16].Value = "2015-02-01T10:00:00";
                    _cmd.Parameters[18].Value = DBNull.Value; break;
                case 4: _cmd.Parameters[12].Value = "4567";
                    _cmd.Parameters[14].Value = "2015-01-01T10:00:00";
                    _cmd.Parameters[16].Value = "2015-02-01T10:00:00";
                    _cmd.Parameters[18].Value = 100; break;
            }
            _cmd.ExecuteNonQuery();
        }

        private ConnectionManager _connManager;
        private string _spName;
        private SqlConnection _conn;
        private SqlCommand _cmd;
    }
}
