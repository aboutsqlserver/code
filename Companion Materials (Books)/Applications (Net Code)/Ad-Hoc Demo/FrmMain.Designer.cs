namespace Actsoft.Com.AdHocDemo
{
    partial class frmMain
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.btnStop = new System.Windows.Forms.Button();
            this.btnStart = new System.Windows.Forms.Button();
            this.tbCallsPerSec = new System.Windows.Forms.TextBox();
            this.Label4 = new System.Windows.Forms.Label();
            this.cbScenario = new System.Windows.Forms.ComboBox();
            this.Label3 = new System.Windows.Forms.Label();
            this.tbThreadNum = new System.Windows.Forms.TextBox();
            this.Label2 = new System.Windows.Forms.Label();
            this.tbConnectionString = new System.Windows.Forms.TextBox();
            this.Label1 = new System.Windows.Forms.Label();
            this.btnValidateConnection = new System.Windows.Forms.Button();
            this.label6 = new System.Windows.Forms.Label();
            this.linkLabel1 = new System.Windows.Forms.LinkLabel();
            this.SuspendLayout();
            // 
            // btnStop
            // 
            this.btnStop.Enabled = false;
            this.btnStop.Location = new System.Drawing.Point(285, 142);
            this.btnStop.Margin = new System.Windows.Forms.Padding(2);
            this.btnStop.Name = "btnStop";
            this.btnStop.Size = new System.Drawing.Size(73, 32);
            this.btnStop.TabIndex = 53;
            this.btnStop.Text = "Stop";
            this.btnStop.UseVisualStyleBackColor = true;
            this.btnStop.Click += new System.EventHandler(this.btnStop_Click);
            // 
            // btnStart
            // 
            this.btnStart.Location = new System.Drawing.Point(185, 142);
            this.btnStart.Margin = new System.Windows.Forms.Padding(2);
            this.btnStart.Name = "btnStart";
            this.btnStart.Size = new System.Drawing.Size(73, 32);
            this.btnStart.TabIndex = 52;
            this.btnStart.Text = "Start";
            this.btnStart.UseVisualStyleBackColor = true;
            this.btnStart.Click += new System.EventHandler(this.btnStart_Click);
            // 
            // tbCallsPerSec
            // 
            this.tbCallsPerSec.BackColor = System.Drawing.SystemColors.ControlLight;
            this.tbCallsPerSec.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.tbCallsPerSec.ForeColor = System.Drawing.Color.Red;
            this.tbCallsPerSec.Location = new System.Drawing.Point(267, 97);
            this.tbCallsPerSec.Name = "tbCallsPerSec";
            this.tbCallsPerSec.ReadOnly = true;
            this.tbCallsPerSec.Size = new System.Drawing.Size(113, 26);
            this.tbCallsPerSec.TabIndex = 51;
            // 
            // Label4
            // 
            this.Label4.AutoSize = true;
            this.Label4.Font = new System.Drawing.Font("Microsoft Sans Serif", 8F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Label4.Location = new System.Drawing.Point(162, 104);
            this.Label4.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.Label4.Name = "Label4";
            this.Label4.Size = new System.Drawing.Size(108, 13);
            this.Label4.TabIndex = 50;
            this.Label4.Text = "Calls Per Second:";
            // 
            // cbScenario
            // 
            this.cbScenario.AllowDrop = true;
            this.cbScenario.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cbScenario.FormattingEnabled = true;
            this.cbScenario.Items.AddRange(new object[] {
            "AdHoc",
            "Parameterized"});
            this.cbScenario.Location = new System.Drawing.Point(235, 33);
            this.cbScenario.Margin = new System.Windows.Forms.Padding(2);
            this.cbScenario.Name = "cbScenario";
            this.cbScenario.Size = new System.Drawing.Size(305, 21);
            this.cbScenario.TabIndex = 49;
            // 
            // Label3
            // 
            this.Label3.AutoSize = true;
            this.Label3.Location = new System.Drawing.Point(165, 37);
            this.Label3.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.Label3.Name = "Label3";
            this.Label3.Size = new System.Drawing.Size(52, 13);
            this.Label3.TabIndex = 48;
            this.Label3.Text = "Scenario:";
            // 
            // tbThreadNum
            // 
            this.tbThreadNum.Location = new System.Drawing.Point(107, 33);
            this.tbThreadNum.Margin = new System.Windows.Forms.Padding(2);
            this.tbThreadNum.Name = "tbThreadNum";
            this.tbThreadNum.Size = new System.Drawing.Size(45, 20);
            this.tbThreadNum.TabIndex = 47;
            this.tbThreadNum.Text = "4";
            // 
            // Label2
            // 
            this.Label2.AutoSize = true;
            this.Label2.Location = new System.Drawing.Point(33, 36);
            this.Label2.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.Label2.Name = "Label2";
            this.Label2.Size = new System.Drawing.Size(71, 13);
            this.Label2.TabIndex = 46;
            this.Label2.Text = "# of Threads:";
            // 
            // tbConnectionString
            // 
            this.tbConnectionString.Location = new System.Drawing.Point(107, 8);
            this.tbConnectionString.Margin = new System.Windows.Forms.Padding(2);
            this.tbConnectionString.Name = "tbConnectionString";
            this.tbConnectionString.Size = new System.Drawing.Size(411, 20);
            this.tbConnectionString.TabIndex = 45;
            // 
            // Label1
            // 
            this.Label1.AutoSize = true;
            this.Label1.Location = new System.Drawing.Point(10, 10);
            this.Label1.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.Label1.Name = "Label1";
            this.Label1.Size = new System.Drawing.Size(94, 13);
            this.Label1.TabIndex = 44;
            this.Label1.Text = "Connection String:";
            // 
            // btnValidateConnection
            // 
            this.btnValidateConnection.Location = new System.Drawing.Point(522, 11);
            this.btnValidateConnection.Margin = new System.Windows.Forms.Padding(2);
            this.btnValidateConnection.Name = "btnValidateConnection";
            this.btnValidateConnection.Size = new System.Drawing.Size(16, 15);
            this.btnValidateConnection.TabIndex = 54;
            this.btnValidateConnection.Text = ".";
            this.btnValidateConnection.UseVisualStyleBackColor = true;
            this.btnValidateConnection.Click += new System.EventHandler(this.btnValidateConnection_Click);
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label6.Location = new System.Drawing.Point(198, 227);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(147, 13);
            this.label6.TabIndex = 56;
            this.label6.Text = "Written by Dmitri Korotkevitch";
            // 
            // linkLabel1
            // 
            this.linkLabel1.AutoSize = true;
            this.linkLabel1.Location = new System.Drawing.Point(206, 249);
            this.linkLabel1.Name = "linkLabel1";
            this.linkLabel1.Size = new System.Drawing.Size(130, 13);
            this.linkLabel1.TabIndex = 57;
            this.linkLabel1.TabStop = true;
            this.linkLabel1.Text = "http://aboutsqlserver.com";
            this.linkLabel1.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.linkLabel1_LinkClicked);
            // 
            // frmMain
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(543, 271);
            this.Controls.Add(this.linkLabel1);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.btnValidateConnection);
            this.Controls.Add(this.btnStop);
            this.Controls.Add(this.btnStart);
            this.Controls.Add(this.tbCallsPerSec);
            this.Controls.Add(this.Label4);
            this.Controls.Add(this.cbScenario);
            this.Controls.Add(this.Label3);
            this.Controls.Add(this.tbThreadNum);
            this.Controls.Add(this.Label2);
            this.Controls.Add(this.tbConnectionString);
            this.Controls.Add(this.Label1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Margin = new System.Windows.Forms.Padding(2);
            this.MaximizeBox = false;
            this.Name = "frmMain";
            this.Text = "AdHocDemo";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.frmMain_FormClosing);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        internal System.Windows.Forms.Button btnStop;
        internal System.Windows.Forms.Button btnStart;
        private System.Windows.Forms.TextBox tbCallsPerSec;
        internal System.Windows.Forms.Label Label4;
        internal System.Windows.Forms.ComboBox cbScenario;
        internal System.Windows.Forms.Label Label3;
        internal System.Windows.Forms.TextBox tbThreadNum;
        internal System.Windows.Forms.Label Label2;
        internal System.Windows.Forms.TextBox tbConnectionString;
        internal System.Windows.Forms.Label Label1;
        private System.Windows.Forms.Button btnValidateConnection;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.LinkLabel linkLabel1;
    }
}

