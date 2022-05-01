/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 13. Temporary Objects and TempDB                   */
/*             Saving Batch of Rows from Client Application                 */
/****************************************************************************/
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Data.SqlClient;
using System.Diagnostics;

namespace SaveRecordSetApp
{
    public partial class MainForm : Form
    {
        public MainForm()
        {
            InitializeComponent();
            if (System.Configuration.ConfigurationManager.ConnectionStrings["ConnStr"] != null)
                tbConnString.Text = System.Configuration.ConfigurationManager.ConnectionStrings["ConnStr"].ConnectionString;
        }

        private int GetPacketSize()
        {
            int result;
            if (!Int32.TryParse(tbPacketSize.Text, out result))
            {
                MessageBox.Show("Invalid packet size. Using 5000", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return 5000;
            }
            return result;
        }

        private SqlConnection GetConnection()
        {
            SqlConnection conn = new SqlConnection(tbConnString.Text);
            conn.Open();
            return conn;
        }

        private bool IsTVPSupported()
        {
            using (SqlConnection conn = GetConnection())
            {
                SqlCommand cmd = new SqlCommand(@"select @Ver = convert(int,	left(convert(nvarchar(128), serverproperty('ProductVersion')), 
                                        charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1))", conn);
                cmd.Parameters.Add("@Ver", SqlDbType.Int).Direction = ParameterDirection.Output;
                cmd.ExecuteNonQuery();
                return (int)(cmd.Parameters[0].Value) > 9;
            }
        }


        private void TruncateTable()
        {
            using (SqlConnection conn = GetConnection())
            {
                SqlCommand cmd = new SqlCommand("truncate table dbo.DataRecords", conn);
                cmd.ExecuteNonQuery();
            }
        }

        private void btnSeparateInserts_Click(object sender, EventArgs e)
        {
            TimeSpan workTime;
            int packetSize = GetPacketSize();

            TruncateTable();
            using (SqlConnection conn = GetConnection())
            {
                DateTime startTime = DateTime.Now;
                SqlCommand insertCmd = new SqlCommand(
                    @"insert into dbo.DataRecords(ID,Col1,Col2,Col3,Col4,Col5,
                        Col6,Col7,Col8,Col9,Col10,Col11,Col12,Col13,
	                    Col14,Col15,Col16,Col17,Col18,Col19,Col20)
                    values(@ID,@Col1,@Col2,@Col3,@Col4,@Col5
                    ,@Col6,@Col7,@Col8,@Col9,@Col10,@Col11,@Col12,@Col13
                    ,@Col14,@Col15,@Col16,@Col17,@Col18,@Col19,@Col20)",conn);
                insertCmd.Parameters.Add("@ID", SqlDbType.Int);
                for (int i = 1; i <= 20; i++)
                    insertCmd.Parameters.Add("@Col" + i.ToString(), SqlDbType.VarChar, 20);
                using (SqlTransaction tran = conn.BeginTransaction(IsolationLevel.ReadCommitted))
                {
                    try
                    {
                        insertCmd.Transaction = tran;

                        for (int i = 0; i < packetSize; i++)
                        {
                            insertCmd.Parameters[0].Value = i;
                            for (int p = 1; p <= 20; p++)
                                insertCmd.Parameters[p].Value = "Parameter: " + p.ToString();
                            insertCmd.ExecuteNonQuery();
                        }
                        tran.Commit();
                    }
                    catch (Exception ex)
                    {
                        tran.Rollback();
                        MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
                workTime = DateTime.Now - startTime;
            }
            MessageBox.Show(lblSiResult.Text = String.Format("Execution Time: {0} ms",(int)workTime.TotalMilliseconds), 
                "Execution Statistics", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void btnTvp_Click(object sender, EventArgs e)
        {
            if (!IsTVPSupported())
            {
                MessageBox.Show(lblTVPResult.Text = "You should have SQL Server 2008+ to use TVP", 
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            TimeSpan workTime1, workTime2;
            int packetSize = GetPacketSize();

            TruncateTable();
            using (SqlConnection conn = GetConnection())
            {
                DateTime startTime = DateTime.Now;
                DataTable table = new DataTable();
                table.Columns.Add("ID", typeof(Int32));
                for (int i = 1; i <= 20; i++)
                    table.Columns.Add("Col" + i.ToString(), typeof(string));
                for (int i = 0; i < packetSize; i++)
                    table.Rows.Add(i, "Parameter: 1", "Parameter: 2", "Parameter: 3",
                        "Parameter: 4", "Parameter: 5", "Parameter: 6", "Parameter: 7",
                        "Parameter: 8", "Parameter: 9", "Parameter: 10", "Parameter: 11",
                        "Parameter: 12", "Parameter: 13", "Parameter: 14", "Parameter: 15",
                        "Parameter: 16", "Parameter: 17", "Parameter: 18", "Parameter: 19",
                        "Parameter: 20");
                workTime1 = DateTime.Now - startTime;
                SqlCommand insertCmd = new SqlCommand("dbo.InsertDataRecordsTVP", conn);
                insertCmd.Parameters.Add("@Data", SqlDbType.Structured);
                insertCmd.Parameters[0].TypeName = "dbo.DataRecordsTVP";
                insertCmd.Parameters[0].Value = table;
				insertCmd.ExecuteNonQuery();
                workTime2 = DateTime.Now - startTime;
            }
            MessageBox.Show(
                lblTVPResult.Text = 
                    String.Format("Preparation Time: {0} ms; Execution Time: {1} ms", (int)workTime1.TotalMilliseconds,(int)workTime2.TotalMilliseconds), 
                "Execution Statistics", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private string PrepareElementCentricXml(int packetSize)
		{
			StringBuilder sb = new StringBuilder("<Recs>");
			for (int i = 0; i < packetSize; i++)
				sb.AppendFormat(
@"<R><ID>{0}</ID><F1>{1}</F1><F2>{2}</F2><F3>{3}</F3><F4>{4}</F4><F5>{5}</F5><F6>{6}</F6><F7>{7}</F7><F8>{8}</F8><F9>{9}</F9><F10>{10}</F10>" +
@"<F11>{11}</F11><F12>{12}</F12><F13>{13}</F13><F14>{14}</F14><F15>{15}</F15><F16>{16}</F16><F17>{17}</F17><F18>{18}</F18><F19>{19}</F19><F20>{20}</F20></R>",
i, "Parameter: 1", "Parameter: 2", "Parameter: 3","Parameter: 4", "Parameter: 5", "Parameter: 6", "Parameter: 7","Parameter: 8", "Parameter: 9", "Parameter: 10", 
"Parameter: 11","Parameter: 12", "Parameter: 13", "Parameter: 14", "Parameter: 15","Parameter: 16", "Parameter: 17", "Parameter: 18", "Parameter: 19",
					"Parameter: 20");
			sb.Append("</Recs>");
			return sb.ToString();
		}

        
        private void btnElementCentric_Click(object sender, EventArgs e)
		{
			TimeSpan workTime1, workTime2;
			int packetSize = GetPacketSize();

			TruncateTable();
			DateTime startTime = DateTime.Now;
			string xml = PrepareElementCentricXml(packetSize);
			workTime1 = DateTime.Now - startTime;
			using (SqlConnection conn = GetConnection())
			{
				SqlCommand insertCmd = new SqlCommand("dbo.InsertDataRecordsElementsXml", conn);
				insertCmd.CommandType = CommandType.StoredProcedure;
				insertCmd.Parameters.Add("@Data", SqlDbType.Xml);
				insertCmd.Parameters[0].Value = xml;
                insertCmd.CommandTimeout = 0;
				insertCmd.ExecuteNonQuery();
				workTime2 = DateTime.Now - startTime;
			}
            MessageBox.Show(
                lblECXMLResult.Text =
                    String.Format("Preparation Time: {0} ms; Execution Time: {1} ms", (int)workTime1.TotalMilliseconds, (int)workTime2.TotalMilliseconds),
                "Execution Statistics", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }


        private string PrepareJSON(int packetSize)
        {
            StringBuilder sb = new StringBuilder("[");
            for (int i = 0; i < packetSize; i++)
                sb.AppendFormat(
"{{\"ID\":{0},\"F1\":\"{1}\",\"F2\":\"{2}\",\"F3\":\"{3}\",\"F4\":\"{4}\",\"F5\":\"{5}\",\"F6\":\"{6}\",\"F7\":\"{7}\",\"F8\":\"{8}\",\"F9\":\"{9}\",\"F10\":\"{10}\"" +
",\"F11\":\"{11}\",\"F12\":\"{12}\",\"F13\":\"{13}\",\"F14\":\"{14}\",\"F15\":\"{15}\",\"F16\":\"{16}\",\"F17\":\"{17}\",\"F18\":\"{18}\",\"F19\":\"{19}\",\"F20\":\"{20}\"}}{21}",
i, "Parameter: 1", "Parameter: 2", "Parameter: 3", "Parameter: 4", "Parameter: 5", "Parameter: 6", "Parameter: 7", "Parameter: 8", "Parameter: 9", "Parameter: 10",
"Parameter: 11", "Parameter: 12", "Parameter: 13", "Parameter: 14", "Parameter: 15", "Parameter: 16", "Parameter: 17", "Parameter: 18", "Parameter: 19",
                    "Parameter: 20",(i < packetSize - 1) ? "," : "]");
            return sb.ToString();
        }

        private string PrepareAttributeCentricXml(int packetSize)
        {
            StringBuilder sb = new StringBuilder("<Recs>");
            for (int i = 0; i < packetSize; i++)
                sb.AppendFormat(
"<R ID=\"{0}\" F1=\"{1}\" F2=\"{2}\" F3=\"{3}\" F4=\"{4}\" F5=\"{5}\" F6=\"{6}\" F7=\"{7}\" F8=\"{8}\" F9=\"{9}\" F10=\"{10}\" " +
"F11=\"{11}\" F12=\"{12}\" F13=\"{13}\" F14=\"{14}\" F15=\"{15}\" F16=\"{16}\" F17=\"{17}\" F18=\"{18}\" F19=\"{19}\" F20=\"{20}\" />",
i, "Parameter: 1", "Parameter: 2", "Parameter: 3", "Parameter: 4", "Parameter: 5", "Parameter: 6", "Parameter: 7", "Parameter: 8", "Parameter: 9", "Parameter: 10",
"Parameter: 11", "Parameter: 12", "Parameter: 13", "Parameter: 14", "Parameter: 15", "Parameter: 16", "Parameter: 17", "Parameter: 18", "Parameter: 19",
                    "Parameter: 20");
            sb.Append("</Recs>");
            return sb.ToString();
        }
        
        private void btnAttributeCentric_Click(object sender, EventArgs e)
		{
			TimeSpan workTime1, workTime2;
			int packetSize = GetPacketSize();

			TruncateTable();
			DateTime startTime = DateTime.Now;
			string xml = PrepareAttributeCentricXml(packetSize);
			workTime1 = DateTime.Now - startTime;
			using (SqlConnection conn = GetConnection())
			{
				SqlCommand insertCmd = new SqlCommand(
                       (sender == btnAttributeCentric) ? "dbo.InsertDataRecordsAttrXml" : "dbo.InsertDataRecordsAttrXml2", conn);
				insertCmd.CommandType = CommandType.StoredProcedure;
				insertCmd.Parameters.Add("@Data", SqlDbType.Xml);
				insertCmd.Parameters[0].Value = xml;
                insertCmd.CommandTimeout = 0;
                insertCmd.ExecuteNonQuery();
				workTime2 = DateTime.Now - startTime;
			}
            string s = String.Format("Preparation Time: {0} ms; Execution Time: {1} ms", (int)workTime1.TotalMilliseconds, (int)workTime2.TotalMilliseconds);
            if (sender == btnAttributeCentric)
                lblACXMLResult.Text = s;
            else
                lblACTTXMLResult.Text = s;
            MessageBox.Show(s,"Execution Statistics", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        
       
        private void btnOpenXml_Click(object sender, EventArgs e)
		{
			TimeSpan workTime1, workTime2;
			int packetSize = GetPacketSize();

			TruncateTable();
			DateTime startTime = DateTime.Now;
			string xml = PrepareAttributeCentricXml(packetSize);
			workTime1 = DateTime.Now - startTime;
			using (SqlConnection conn = GetConnection())
			{
				SqlCommand insertCmd = new SqlCommand("dbo.InsertDataRecordsOpenXML", conn);
				insertCmd.CommandType = CommandType.StoredProcedure;
				insertCmd.Parameters.Add("@Data", SqlDbType.Xml);
				insertCmd.Parameters[0].Value = xml;
				insertCmd.ExecuteNonQuery();
				workTime2 = DateTime.Now - startTime;
			}
            MessageBox.Show(
                lblOXMLResult.Text =
                    String.Format("Preparation Time: {0} ms; Execution Time: {1} ms", (int)workTime1.TotalMilliseconds, (int)workTime2.TotalMilliseconds),
                "Execution Statistics", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void btnBulkCopy_Click(object sender, EventArgs e)
        {
            TimeSpan workTime1, workTime2;
            int packetSize = GetPacketSize();

            TruncateTable();
            using (SqlConnection conn = GetConnection())
            {
                DateTime startTime = DateTime.Now;
                DataTable table = new DataTable();
                table.Columns.Add("ID", typeof(Int32));
                for (int i = 1; i <= 20; i++)
                    table.Columns.Add("Col" + i.ToString(), typeof(string));
                for (int i = 0; i < packetSize; i++)
                    table.Rows.Add(i, "Parameter: 1", "Parameter: 2", "Parameter: 3",
                        "Parameter: 4", "Parameter: 5", "Parameter: 6", "Parameter: 7",
                        "Parameter: 8", "Parameter: 9", "Parameter: 10", "Parameter: 11",
                        "Parameter: 12", "Parameter: 13", "Parameter: 14", "Parameter: 15",
                        "Parameter: 16", "Parameter: 17", "Parameter: 18", "Parameter: 19",
                        "Parameter: 20");
                workTime1 = DateTime.Now - startTime;
                using (SqlBulkCopy bc = new SqlBulkCopy(conn))
                {
                    bc.BatchSize = packetSize;
                    bc.DestinationTableName = "dbo.DataRecords";
                    bc.WriteToServer(table);
                }
                workTime2 = DateTime.Now - startTime;
            }
            MessageBox.Show(
                lblBCResult.Text =
                    String.Format("Preparation Time: {0} ms; Execution Time: {1} ms", (int)workTime1.TotalMilliseconds, (int)workTime2.TotalMilliseconds),
                "Execution Statistics", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private bool CheckDBCompatLevel()
        {
            using (SqlConnection conn = GetConnection())
            {
                SqlCommand cmd = new SqlCommand("select @CompatLevel = compatibility_level from sys.databases where database_id = DB_ID()", conn);
                cmd.Parameters.Add("@CompatLevel", SqlDbType.TinyInt).Direction = ParameterDirection.Output;
                cmd.ExecuteNonQuery();
                return (byte)cmd.Parameters[0].Value >= 130;
            }
        }

        private void btnJSON_Click(object sender, EventArgs e)
        {
            if (!CheckDBCompatLevel())
            {
                MessageBox.Show("OPENJSON method is supported in SQL Server 2016 for databases with compatibility_level = 130","Error",MessageBoxButtons.OK,MessageBoxIcon.Error);
                return;
            } 
            TimeSpan workTime1, workTime2;
            int packetSize = GetPacketSize();

            TruncateTable();
            DateTime startTime = DateTime.Now;
            string json = PrepareJSON(packetSize);
            workTime1 = DateTime.Now - startTime;
            using (SqlConnection conn = GetConnection())
            {
                SqlCommand insertCmd = new SqlCommand("dbo.InsertDataRecordsJSON", conn);
                insertCmd.CommandType = CommandType.StoredProcedure;
                insertCmd.Parameters.Add("@Data", SqlDbType.NVarChar,-1);
                insertCmd.Parameters[0].Value = json;
                insertCmd.ExecuteNonQuery();
                workTime2 = DateTime.Now - startTime;
            }
            MessageBox.Show(
                lblJSONResult.Text =
                    String.Format("Preparation Time: {0} ms; Execution Time: {1} ms", (int)workTime1.TotalMilliseconds, (int)workTime2.TotalMilliseconds),
                "Execution Statistics", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void lblURL_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e)
        {
            ProcessStartInfo sInfo = new ProcessStartInfo("http://aboutsqlserver.com");
            Process.Start(sInfo);
        }

    }
}
