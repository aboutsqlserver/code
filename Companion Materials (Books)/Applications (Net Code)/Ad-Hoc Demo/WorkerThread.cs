/****************************************************************************/
/*  Cautionary Tale of Recompilations, Excessive CPU Load and Plan Caching  */
/*                         Dmitri V. Korotkevitch                           */
/*                        http://aboutsqlserver.com                         */
/*                          dk@aboutsqlserver.com                           */
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

namespace Actsoft.Com.AdHocDemo
{
    public  class WorkerThread : BaseThread
    {
        public WorkerThread(ConnectionManager connManager, int scenario) : base(0) 
        {
            this._connManager = connManager;
            this._scenario = scenario;
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
            SqlCommand cmd = new SqlCommand();
            if (_scenario == 1) // Parameterized
            {
                cmd.CommandText = "select top 1 OrderId from dbo.Orders where CustomerId = @CustomerId";
                cmd.Parameters.Add("@CustomerId", SqlDbType.UniqueIdentifier);
            }  
            return cmd;
        }

        protected sealed override void DoIteration()
        {
            if (_scenario == 0)
            {
                _cmd.CommandText = "select top 1 OrderId from dbo.Orders where CustomerId = '" + Guid.NewGuid().ToString() + "'"; 
            }
            else
            {
                _cmd.Parameters[0].Value = Guid.NewGuid();
            }
            using (SqlDataReader reader = _cmd.ExecuteReader())
            {
                reader.Close();
            }
        }

        private ConnectionManager _connManager;
        private int _scenario;
        private SqlConnection _conn;
        private SqlCommand _cmd;
    }
}
