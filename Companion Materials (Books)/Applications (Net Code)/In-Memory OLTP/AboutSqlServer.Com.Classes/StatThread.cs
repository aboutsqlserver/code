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

namespace AboutSqlServer.Com.Classes
{
    public abstract class StatThread : BaseThread
    {
        public StatThread(int sleep, List<BaseThread> threads)
            : base(sleep)
        {
            _threads = threads;
        }

        public int WorkerThreadsCallsPerSec
        {
            get
            {
                int callsPerSec = 0;
                foreach (BaseThread thread in _threads)
                    callsPerSec += thread.CallsPerSec;
                return callsPerSec;
            }
        }

        private List<BaseThread> _threads;
    }
}
