namespace Actsoft.Com.SessionStoreDemo
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
            this.Label3 = new System.Windows.Forms.Label();
            this.tbThreadNum = new System.Windows.Forms.TextBox();
            this.Label2 = new System.Windows.Forms.Label();
            this.tbConnectionString = new System.Windows.Forms.TextBox();
            this.Label1 = new System.Windows.Forms.Label();
            this.btnValidateConnection = new System.Windows.Forms.Button();
            this.label5 = new System.Windows.Forms.Label();
            this.label6 = new System.Windows.Forms.Label();
            this.linkLabel1 = new System.Windows.Forms.LinkLabel();
            this.cbUseInMemoryOLTP = new System.Windows.Forms.CheckBox();
            this.tbSessionSize = new System.Windows.Forms.TextBox();
            this.tbNumIterations = new System.Windows.Forms.TextBox();
            this.label7 = new System.Windows.Forms.Label();
            this.SuspendLayout();
            // 
            // btnStop
            // 
            this.btnStop.Enabled = false;
            this.btnStop.Location = new System.Drawing.Point(285, 177);
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
            this.btnStart.Location = new System.Drawing.Point(185, 177);
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
            this.tbCallsPerSec.Location = new System.Drawing.Point(267, 132);
            this.tbCallsPerSec.Name = "tbCallsPerSec";
            this.tbCallsPerSec.ReadOnly = true;
            this.tbCallsPerSec.Size = new System.Drawing.Size(113, 26);
            this.tbCallsPerSec.TabIndex = 51;
            // 
            // Label4
            // 
            this.Label4.AutoSize = true;
            this.Label4.Font = new System.Drawing.Font("Microsoft Sans Serif", 8F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Label4.Location = new System.Drawing.Point(162, 139);
            this.Label4.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.Label4.Name = "Label4";
            this.Label4.Size = new System.Drawing.Size(108, 13);
            this.Label4.TabIndex = 50;
            this.Label4.Text = "Calls Per Second:";
            // 
            // Label3
            // 
            this.Label3.AutoSize = true;
            this.Label3.Location = new System.Drawing.Point(41, 59);
            this.Label3.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.Label3.Name = "Label3";
            this.Label3.Size = new System.Drawing.Size(105, 13);
            this.Label3.TabIndex = 48;
            this.Label3.Text = "Session Size (Bytes):";
            // 
            // tbThreadNum
            // 
            this.tbThreadNum.Location = new System.Drawing.Point(150, 32);
            this.tbThreadNum.Margin = new System.Windows.Forms.Padding(2);
            this.tbThreadNum.Name = "tbThreadNum";
            this.tbThreadNum.Size = new System.Drawing.Size(67, 20);
            this.tbThreadNum.TabIndex = 47;
            this.tbThreadNum.Text = "30";
            // 
            // Label2
            // 
            this.Label2.AutoSize = true;
            this.Label2.Location = new System.Drawing.Point(75, 35);
            this.Label2.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.Label2.Name = "Label2";
            this.Label2.Size = new System.Drawing.Size(71, 13);
            this.Label2.TabIndex = 46;
            this.Label2.Text = "# of Threads:";
            // 
            // tbConnectionString
            // 
            this.tbConnectionString.Location = new System.Drawing.Point(150, 8);
            this.tbConnectionString.Margin = new System.Windows.Forms.Padding(2);
            this.tbConnectionString.Name = "tbConnectionString";
            this.tbConnectionString.Size = new System.Drawing.Size(368, 20);
            this.tbConnectionString.TabIndex = 45;
            // 
            // Label1
            // 
            this.Label1.AutoSize = true;
            this.Label1.Location = new System.Drawing.Point(52, 11);
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
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label5.Location = new System.Drawing.Point(87, 240);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(369, 15);
            this.label5.TabIndex = 55;
            this.label5.Text = "Expert SQL Server In-Memory OLTP Companion Material";
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label6.Location = new System.Drawing.Point(198, 262);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(147, 13);
            this.label6.TabIndex = 56;
            this.label6.Text = "Written by Dmitri Korotkevitch";
            // 
            // linkLabel1
            // 
            this.linkLabel1.AutoSize = true;
            this.linkLabel1.Location = new System.Drawing.Point(206, 284);
            this.linkLabel1.Name = "linkLabel1";
            this.linkLabel1.Size = new System.Drawing.Size(130, 13);
            this.linkLabel1.TabIndex = 57;
            this.linkLabel1.TabStop = true;
            this.linkLabel1.Text = "http://aboutsqlserver.com";
            this.linkLabel1.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.linkLabel1_LinkClicked);
            // 
            // cbUseInMemoryOLTP
            // 
            this.cbUseInMemoryOLTP.AutoSize = true;
            this.cbUseInMemoryOLTP.Checked = true;
            this.cbUseInMemoryOLTP.CheckState = System.Windows.Forms.CheckState.Checked;
            this.cbUseInMemoryOLTP.Location = new System.Drawing.Point(235, 32);
            this.cbUseInMemoryOLTP.Name = "cbUseInMemoryOLTP";
            this.cbUseInMemoryOLTP.Size = new System.Drawing.Size(128, 17);
            this.cbUseInMemoryOLTP.TabIndex = 58;
            this.cbUseInMemoryOLTP.Text = "Use In-Memory OLTP";
            this.cbUseInMemoryOLTP.UseVisualStyleBackColor = true;
            // 
            // tbSessionSize
            // 
            this.tbSessionSize.Location = new System.Drawing.Point(150, 56);
            this.tbSessionSize.Margin = new System.Windows.Forms.Padding(2);
            this.tbSessionSize.Name = "tbSessionSize";
            this.tbSessionSize.Size = new System.Drawing.Size(67, 20);
            this.tbSessionSize.TabIndex = 59;
            this.tbSessionSize.Text = "5000";
            // 
            // tbNumIterations
            // 
            this.tbNumIterations.Location = new System.Drawing.Point(150, 79);
            this.tbNumIterations.Margin = new System.Windows.Forms.Padding(2);
            this.tbNumIterations.Name = "tbNumIterations";
            this.tbNumIterations.Size = new System.Drawing.Size(67, 20);
            this.tbNumIterations.TabIndex = 62;
            this.tbNumIterations.Text = "5";
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Location = new System.Drawing.Point(38, 82);
            this.label7.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(108, 13);
            this.label7.TabIndex = 61;
            this.label7.Text = "Iterations per Session";
            // 
            // frmMain
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(543, 308);
            this.Controls.Add(this.tbNumIterations);
            this.Controls.Add(this.label7);
            this.Controls.Add(this.tbSessionSize);
            this.Controls.Add(this.cbUseInMemoryOLTP);
            this.Controls.Add(this.linkLabel1);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.btnValidateConnection);
            this.Controls.Add(this.btnStop);
            this.Controls.Add(this.btnStart);
            this.Controls.Add(this.tbCallsPerSec);
            this.Controls.Add(this.Label4);
            this.Controls.Add(this.Label3);
            this.Controls.Add(this.tbThreadNum);
            this.Controls.Add(this.Label2);
            this.Controls.Add(this.tbConnectionString);
            this.Controls.Add(this.Label1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Margin = new System.Windows.Forms.Padding(2);
            this.MaximizeBox = false;
            this.Name = "frmMain";
            this.Text = "Session-Store Demo";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.frmMain_FormClosing);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        internal System.Windows.Forms.Button btnStop;
        internal System.Windows.Forms.Button btnStart;
        private System.Windows.Forms.TextBox tbCallsPerSec;
        internal System.Windows.Forms.Label Label4;
        internal System.Windows.Forms.Label Label3;
        internal System.Windows.Forms.TextBox tbThreadNum;
        internal System.Windows.Forms.Label Label2;
        internal System.Windows.Forms.TextBox tbConnectionString;
        internal System.Windows.Forms.Label Label1;
        private System.Windows.Forms.Button btnValidateConnection;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.LinkLabel linkLabel1;
        private System.Windows.Forms.CheckBox cbUseInMemoryOLTP;
        internal System.Windows.Forms.TextBox tbSessionSize;
        internal System.Windows.Forms.TextBox tbNumIterations;
        internal System.Windows.Forms.Label label7;
    }
}

