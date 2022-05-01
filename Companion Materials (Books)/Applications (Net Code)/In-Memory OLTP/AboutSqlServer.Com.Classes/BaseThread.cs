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
using System.Threading;
using System.Threading.Tasks;

namespace AboutSqlServer.Com.Classes
{
    public abstract class BaseThread
    {
        public BaseThread(int sleep)
        {
            _thread = new Thread(this.Execute);
            _sleep = sleep;
            _terminated = true;
            _iteration = 0;
        }

        public void Start()
        {
            _active = true;
            _terminated = false;
            OnStart();
            _thread.Start();
        }

        public void Terminate()
        {
            if (IsActive)
            {
                _terminated = true;
                OnTerminate();
            }

        }

        public int CallsPerSec
        {
            get
            {
                // We are not using any thread sync constructs - we do not worry much about possible error.
                return (_iteration == 0) ? 0 : (int)(1000 * _iteration / DateTime.Now.Subtract(_startTime).TotalMilliseconds);
            }
        }

        protected virtual void OnTerminate() { }
        protected virtual void OnStart() { }
        protected virtual void OnExecute() { _iteration = 0; _startTime = DateTime.Now; }

        private void Execute()
        {
            using (GetExecuteDisposable())
            {
                OnExecute();
                while (!_terminated)
                {
                    _iteration++;
                    DoIteration();
                    if (_sleep == 0)
                        Thread.Sleep(0);
                    else
                    {
                        int delay = _sleep;
                        while (!_terminated && (delay > 0))
                        {
                            Thread.Sleep((_sleep < 1000) ? _sleep : 1000);
                            delay -= 1000;
                        }
                    }
                }
            }
        }

        protected virtual IDisposable GetExecuteDisposable()
        {
            return null;
        }

        protected abstract void DoIteration();

        public bool IsActive { get { return _active; } }
        public int Iteration { get { return _iteration; } }

        private Thread _thread;
        private int _sleep;

        protected bool _terminated = true;
        protected int _iteration;

        private bool _active = false;

        private DateTime _startTime;
    }
}
