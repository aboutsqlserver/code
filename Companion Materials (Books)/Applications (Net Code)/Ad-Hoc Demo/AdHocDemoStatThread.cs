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
using AboutSqlServer.Com.Classes;

namespace Actsoft.Com.AdHocDemo
{
    public class AdHocDemoStatThread : StatThread
    {
        public AdHocDemoStatThread(int sleep, List<BaseThread> threads, frmMain frmMain)
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
