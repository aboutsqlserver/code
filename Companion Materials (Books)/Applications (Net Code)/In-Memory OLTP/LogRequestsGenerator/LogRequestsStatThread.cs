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
using AboutSqlServer.Com.Classes;

namespace Actsoft.Com.LogRequestsGenerator
{
    public class LogRequestsStatThread : StatThread
    {
        public LogRequestsStatThread(int sleep, List<BaseThread> threads, frmMain frmMain)
            : base(sleep, threads)
        {
            _frmMain = frmMain;
        }

        protected override void DoIteration()
        {
            if (!_terminated)
            {
                _frmMain.Invoke(_frmMain.UpdateExecStats, new object[] { WorkerThreadsCallsPerSec });
            }
        }

        private frmMain _frmMain;
    }
}
