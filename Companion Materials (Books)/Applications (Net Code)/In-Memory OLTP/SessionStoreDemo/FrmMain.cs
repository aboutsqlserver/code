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

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using AboutSqlServer.Com.Classes;
using System.Diagnostics;

namespace Actsoft.Com.SessionStoreDemo
{
    public partial class frmMain : Form
    {
        public frmMain()
        {
            InitializeComponent();
            _connManager = new ConnectionManager("SessionStoreDemo");
            tbConnectionString.Text = String.IsNullOrEmpty(_connManager.ConnStr) ? "Server=.;Database=.;Trusted_Connection=True;" : _connManager.ConnStr;
            UpdateExecStats = new UpdateExecStatsDelegate(this.UpdateExecStatsMethod);
        }

        public void UpdateExecStatsMethod(int callsPerSec)
        {
            tbCallsPerSec.Text = callsPerSec.ToString();
        }


        private void btnStart_Click(object sender, EventArgs e)
        {
            if (_statThread != null)
                MessageBox.Show("Log Requests generation is already running", "Session Store Demo", MessageBoxButtons.OK, MessageBoxIcon.Error);
            else
            {
                Start();
            }
        }

        private void Start()
        {
            int threadCount, sessionSize, iterationsPerSession;
            string errMsg;
            if (!Int32.TryParse(tbThreadNum.Text, out threadCount))
            {
                MessageBox.Show("Invalid # of Threads", "Session Store Demo", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            if (!Int32.TryParse(tbSessionSize.Text, out sessionSize))
            {
                MessageBox.Show("Invalid Session Size", "Session Store Demo", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            if (!Int32.TryParse(tbNumIterations.Text, out iterationsPerSession))
            {
                MessageBox.Show("Invalid # of Iterations per Session", "Session Store Demo", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            if (String.IsNullOrEmpty(tbConnectionString.Text))
            {
                MessageBox.Show("Please specify connection string", "Session Store Demo", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            _connManager.ConnStr = tbConnectionString.Text;
            if (!_connManager.ValidateConnection(out errMsg))
            {
                MessageBox.Show(
                       String.Format("Cannot validate database connection. Error: {0}", errMsg),
                       "Session Store Demo", MessageBoxButtons.OK, MessageBoxIcon.Error
                );
                return;
            }
            _threads = new List<BaseThread>(threadCount);
            for (int i = 0; i < threadCount; i++)
                _threads.Add(new WorkerThread(_connManager,cbUseInMemoryOLTP.Checked,sessionSize,iterationsPerSession));
             foreach (WorkerThread thread in _threads)
                thread.Start();
            _statThread = new SessionStoreStatThread(5000, _threads, this);
            _statThread.Start();
            btnStart.Enabled = false;
            btnStop.Enabled = true;
        }

        private void btnStop_Click(object sender, EventArgs e)
        {
            if (_statThread == null)
                MessageBox.Show("Utility is not running", "Session Store Demo", MessageBoxButtons.OK, MessageBoxIcon.Error);
            else
            {
                Stop();
                MessageBox.Show("Stopped!", "Session Store Demo", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private void Stop()
        {
            _statThread.Terminate();
            foreach (WorkerThread thread in _threads)
                thread.Terminate();
            System.Threading.Thread.Sleep(3000);
            _statThread = null;
            _threads = null;
            btnStart.Enabled = true;
            btnStop.Enabled = false;
        }

        private void frmMain_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (_statThread != null)
            {
                Stop();
                System.Threading.Thread.Sleep(1500);
            }
        }

        private void btnValidateConnection_Click(object sender, EventArgs e)
        {
            if (String.IsNullOrEmpty(tbConnectionString.Text))
            {
                MessageBox.Show("Please specify connection string", "Session Store Demo", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            string errMsg;
            _connManager.ConnStr = tbConnectionString.Text;
            if (!_connManager.ValidateConnection(out errMsg))
                MessageBox.Show(String.Format("Cannot validate database connection. Error: {0}", errMsg), "Session Store Demo", MessageBoxButtons.OK, MessageBoxIcon.Error);
            else
                MessageBox.Show("OK!", "Session Store Demo", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void linkLabel1_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e)
        {
            ProcessStartInfo sInfo = new ProcessStartInfo("http://aboutsqlserver.com");
            Process.Start(sInfo);
        }

        public delegate void UpdateExecStatsDelegate(int callsPerSec);
        public UpdateExecStatsDelegate UpdateExecStats;
        private List<BaseThread> _threads;
        private SessionStoreStatThread _statThread;
        private ConnectionManager _connManager;

    }
}
