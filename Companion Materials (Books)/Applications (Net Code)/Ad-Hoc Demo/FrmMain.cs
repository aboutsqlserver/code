/****************************************************************************/
/*  Cautionary Tale of Recompilations, Excessive CPU Load and Plan Caching  */
/*                         Dmitri V. Korotkevitch                           */
/*                        http://aboutsqlserver.com                         */
/*                          dk@aboutsqlserver.com                           */
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

namespace Actsoft.Com.AdHocDemo
{
    public partial class frmMain : Form
    {
        public frmMain()
        {
            InitializeComponent();
            _connManager = new ConnectionManager("SQLServerInternalsDB");
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
                MessageBox.Show("Utility is already running", "AdHoc Demo Utility", MessageBoxButtons.OK, MessageBoxIcon.Error);
            else
            {
                Start();
            }
        }

        private void Start()
        {
            int threadCount;
            string errMsg;
            if (!Int32.TryParse(tbThreadNum.Text, out threadCount))
            {
                MessageBox.Show("Invalid # of Threads", "AdHoc Demo Utility", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            if (String.IsNullOrEmpty(cbScenario.Text))
            {
                MessageBox.Show("Please select scenario", "AdHoc Demo Utility", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            if (String.IsNullOrEmpty(tbConnectionString.Text))
            {
                MessageBox.Show("Please specify connection string", "AdHoc Demo Utility", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            _connManager.ConnStr = tbConnectionString.Text;
            if (!_connManager.ValidateConnection(out errMsg))
            {
                MessageBox.Show(
                       String.Format("Cannot validate database connection. Error: {0}", errMsg),
                       "AdHoc Demo Utility", MessageBoxButtons.OK, MessageBoxIcon.Error
                );
                return;
            }

            _threads = new List<BaseThread>(threadCount);
            for (int i = 0; i < threadCount; i++)
                _threads.Add(new WorkerThread(_connManager, cbScenario.SelectedIndex));
            foreach (WorkerThread thread in _threads)
                thread.Start();
            _statThread = new AdHocDemoStatThread(5000, _threads, this);
            _statThread.Start();
            btnStart.Enabled = false;
            btnStop.Enabled = true;
        }

        private void btnStop_Click(object sender, EventArgs e)
        {
            if (_statThread == null)
                MessageBox.Show("Log Requests generation is not running", "AdHoc Demo Utility", MessageBoxButtons.OK, MessageBoxIcon.Error);
            else
            {
                Stop();
                MessageBox.Show("Stopped!", "AdHoc Demo Utility", MessageBoxButtons.OK, MessageBoxIcon.Information);
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
                MessageBox.Show("Please specify connection string", "AdHoc Demo Utility", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            string errMsg;
            _connManager.ConnStr = tbConnectionString.Text;
            if (!_connManager.ValidateConnection(out errMsg))
                MessageBox.Show(String.Format("Cannot validate database connection. Error: {0}", errMsg), "AdHoc Demo Utility", MessageBoxButtons.OK, MessageBoxIcon.Error);
            else
                MessageBox.Show("OK!", "AdHoc Demo Utility", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void linkLabel1_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e)
        {
            ProcessStartInfo sInfo = new ProcessStartInfo("http://aboutsqlserver.com");
            Process.Start(sInfo);
        }

        public delegate void UpdateExecStatsDelegate(int callsPerSec);
        public UpdateExecStatsDelegate UpdateExecStats;
        private List<BaseThread> _threads;
        private AdHocDemoStatThread _statThread;
        private ConnectionManager _connManager;

    }
}
