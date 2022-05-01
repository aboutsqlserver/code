/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*           Written by Dmitri V. Korotkevitch & Vladimir Zatuliveter       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                     Chapter 13 - Session Store Demo                      */
/****************************************************************************/

/******************************************************************************/
/* This is oversimplified example to illustrate the basic concepts. Production *
 * implementation should have additional code to resolve concurrency conflicts *
 /******************************************************************************/


using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using System.Data.SqlClient;
using System.Data;
using AboutSqlServer.Com.Classes;

namespace Actsoft.Com.SessionStoreDemo
{
    public  class WorkerThread : BaseThread
    {
        [Serializable]
        class SessionObject
        {
            public byte[] data;
            public int iteration;

            public SessionObject(int objSize)
            {
                data = Enumerable.Repeat<byte>(0,objSize).ToArray<byte>();
                iteration = 0;
            }
        }

        public WorkerThread(ConnectionManager connManager, bool useInMemOLTP, int objSize, int iterations) : base(0) 
        {
            this._connManager = connManager;
            this._obj = new SessionObject(objSize);
            this._useInMemOLTP = useInMemOLTP;
            this._iterations = iterations;
        }

        protected override IDisposable GetExecuteDisposable()
        {
            _conn = _connManager.GetConnection();
            return _conn;
        }

        protected override void OnExecute()
        {
            base.OnExecute();
            CreateCommands(_conn);
        }

        private void CreateCommands(SqlConnection conn)
        {
            _cmdLoad = new SqlCommand("dbo.LoadObjectFromStore" + (_useInMemOLTP ? String.Empty : "_Disk"), conn);
            _cmdLoad.CommandType = System.Data.CommandType.StoredProcedure;
            _cmdLoad.Parameters.Add("@ObjectKey", SqlDbType.UniqueIdentifier);
            _cmdLoad.Parameters.Add("@Data", SqlDbType.VarBinary,-1).Direction = ParameterDirection.Output;

            _cmdSave = new SqlCommand("dbo.SaveObjectToStore" + (_useInMemOLTP ? String.Empty : "_Disk"), conn);
            _cmdSave.CommandType = System.Data.CommandType.StoredProcedure;
            _cmdSave.Parameters.Add("@ObjectKey", SqlDbType.UniqueIdentifier);
            _cmdSave.Parameters.Add("@ExpirationTime", SqlDbType.DateTime2).Value = DateTime.UtcNow.AddHours(1);
            _cmdSave.Parameters.Add("@Data", SqlDbType.VarBinary, -1);
        }

        protected sealed override void DoIteration()
        {
            if (_iteration % _iterations == 1)
            { // Emulating new session
                _objectKey = Guid.NewGuid();
                _cmdLoad.Parameters[0].Value = _cmdSave.Parameters[0].Value = _objectKey;
            }
            else
            { // Loading data from db
                // Step 1: Getting serialized data
                _cmdLoad.Parameters[0].Value = _objectKey;
                _cmdLoad.ExecuteNonQuery();
                byte[] obj = (byte[])_cmdLoad.Parameters[1].Value;
                if (obj == null)
                    throw new Exception("Cannot locate an object with key: " + _objectKey.ToString());
                SessionObject loadedObj = ObjStoreUtils.Deserialize<SessionObject>(obj);
                // Validation - for demo purposes
                if (loadedObj.iteration != _obj.iteration)
                    throw new Exception("Validation failed: Iterations do not match");
            }
            // Saving object to DB
            _obj.iteration = _iteration;
            _cmdSave.Parameters[2].Value = ObjStoreUtils.Serialize<SessionObject>(_obj); 
            _cmdSave.ExecuteNonQuery();
        }

        private ConnectionManager _connManager;
        private SqlConnection _conn;
        private SqlCommand _cmdLoad;
        private SqlCommand _cmdSave;
        private SessionObject _obj;
        private int _iterations;
        private bool _useInMemOLTP;
        private Guid _objectKey;
    }
}
