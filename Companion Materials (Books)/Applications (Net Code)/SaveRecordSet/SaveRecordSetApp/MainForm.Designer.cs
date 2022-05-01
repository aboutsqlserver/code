namespace SaveRecordSetApp
{
    partial class MainForm
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(MainForm));
            this.lblPacketSize = new System.Windows.Forms.Label();
            this.tbPacketSize = new System.Windows.Forms.TextBox();
            this.btnSeparateInserts = new System.Windows.Forms.Button();
            this.btnTvp = new System.Windows.Forms.Button();
            this.btnElementCentric = new System.Windows.Forms.Button();
            this.btnAttributeCentric = new System.Windows.Forms.Button();
            this.btnOpenXml = new System.Windows.Forms.Button();
            this.btnAttributeCentricTempTable = new System.Windows.Forms.Button();
            this.tbConnString = new System.Windows.Forms.TextBox();
            this.btnBulkCopy = new System.Windows.Forms.Button();
            this.lblSeparateInsertInfo = new System.Windows.Forms.Label();
            this.lblTVPInfo = new System.Windows.Forms.Label();
            this.lblElementCentricXMLInfo = new System.Windows.Forms.Label();
            this.lblAttributeCentricXMLInfo = new System.Windows.Forms.Label();
            this.lblOpenXMLInfo = new System.Windows.Forms.Label();
            this.lblAttributeCentricTempTableInfo = new System.Windows.Forms.Label();
            this.lblSQLBulkCopyInfo = new System.Windows.Forms.Label();
            this.lblURL = new System.Windows.Forms.LinkLabel();
            this.labelBookInfo = new System.Windows.Forms.Label();
            this.lblInfo2 = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.lblSiResult = new System.Windows.Forms.Label();
            this.lblTVPResult = new System.Windows.Forms.Label();
            this.lblECXMLResult = new System.Windows.Forms.Label();
            this.lblACXMLResult = new System.Windows.Forms.Label();
            this.lblOXMLResult = new System.Windows.Forms.Label();
            this.lblACTTXMLResult = new System.Windows.Forms.Label();
            this.lblBCResult = new System.Windows.Forms.Label();
            this.lblJSON = new System.Windows.Forms.Label();
            this.btnJSON = new System.Windows.Forms.Button();
            this.lblJSONResult = new System.Windows.Forms.Label();
            this.SuspendLayout();
            // 
            // lblPacketSize
            // 
            this.lblPacketSize.AutoSize = true;
            this.lblPacketSize.Location = new System.Drawing.Point(13, 95);
            this.lblPacketSize.Name = "lblPacketSize";
            this.lblPacketSize.Size = new System.Drawing.Size(67, 13);
            this.lblPacketSize.TabIndex = 0;
            this.lblPacketSize.Text = "Packet Size:";
            // 
            // tbPacketSize
            // 
            this.tbPacketSize.Location = new System.Drawing.Point(86, 92);
            this.tbPacketSize.Name = "tbPacketSize";
            this.tbPacketSize.Size = new System.Drawing.Size(100, 20);
            this.tbPacketSize.TabIndex = 1;
            this.tbPacketSize.Text = "5000";
            // 
            // btnSeparateInserts
            // 
            this.btnSeparateInserts.Location = new System.Drawing.Point(16, 123);
            this.btnSeparateInserts.Name = "btnSeparateInserts";
            this.btnSeparateInserts.Size = new System.Drawing.Size(137, 23);
            this.btnSeparateInserts.TabIndex = 3;
            this.btnSeparateInserts.Text = "Separate inserts";
            this.btnSeparateInserts.UseVisualStyleBackColor = true;
            this.btnSeparateInserts.Click += new System.EventHandler(this.btnSeparateInserts_Click);
            // 
            // btnTvp
            // 
            this.btnTvp.Location = new System.Drawing.Point(16, 152);
            this.btnTvp.Name = "btnTvp";
            this.btnTvp.Size = new System.Drawing.Size(137, 23);
            this.btnTvp.TabIndex = 4;
            this.btnTvp.Text = "TVP";
            this.btnTvp.UseVisualStyleBackColor = true;
            this.btnTvp.Click += new System.EventHandler(this.btnTvp_Click);
            // 
            // btnElementCentric
            // 
            this.btnElementCentric.Location = new System.Drawing.Point(16, 181);
            this.btnElementCentric.Name = "btnElementCentric";
            this.btnElementCentric.Size = new System.Drawing.Size(137, 23);
            this.btnElementCentric.TabIndex = 5;
            this.btnElementCentric.Text = "Element-Centric XML";
            this.btnElementCentric.UseVisualStyleBackColor = true;
            this.btnElementCentric.Click += new System.EventHandler(this.btnElementCentric_Click);
            // 
            // btnAttributeCentric
            // 
            this.btnAttributeCentric.Location = new System.Drawing.Point(16, 210);
            this.btnAttributeCentric.Name = "btnAttributeCentric";
            this.btnAttributeCentric.Size = new System.Drawing.Size(137, 23);
            this.btnAttributeCentric.TabIndex = 6;
            this.btnAttributeCentric.Text = "Attribute-Centric XML";
            this.btnAttributeCentric.UseVisualStyleBackColor = true;
            this.btnAttributeCentric.Click += new System.EventHandler(this.btnAttributeCentric_Click);
            // 
            // btnOpenXml
            // 
            this.btnOpenXml.Location = new System.Drawing.Point(16, 240);
            this.btnOpenXml.Name = "btnOpenXml";
            this.btnOpenXml.Size = new System.Drawing.Size(137, 23);
            this.btnOpenXml.TabIndex = 7;
            this.btnOpenXml.Text = "Open XML";
            this.btnOpenXml.UseVisualStyleBackColor = true;
            this.btnOpenXml.Click += new System.EventHandler(this.btnOpenXml_Click);
            // 
            // btnAttributeCentricTempTable
            // 
            this.btnAttributeCentricTempTable.Location = new System.Drawing.Point(16, 269);
            this.btnAttributeCentricTempTable.Name = "btnAttributeCentricTempTable";
            this.btnAttributeCentricTempTable.Size = new System.Drawing.Size(137, 41);
            this.btnAttributeCentricTempTable.TabIndex = 8;
            this.btnAttributeCentricTempTable.Text = "Attribute-Centric XML with Temp Table";
            this.btnAttributeCentricTempTable.UseVisualStyleBackColor = true;
            this.btnAttributeCentricTempTable.Click += new System.EventHandler(this.btnAttributeCentric_Click);
            // 
            // tbConnString
            // 
            this.tbConnString.Location = new System.Drawing.Point(204, 92);
            this.tbConnString.Name = "tbConnString";
            this.tbConnString.Size = new System.Drawing.Size(598, 20);
            this.tbConnString.TabIndex = 2;
            this.tbConnString.Text = "Data Source=.;Initial Catalog=SQLServerInternals;Trusted_Connection=True";
            // 
            // btnBulkCopy
            // 
            this.btnBulkCopy.Location = new System.Drawing.Point(16, 316);
            this.btnBulkCopy.Name = "btnBulkCopy";
            this.btnBulkCopy.Size = new System.Drawing.Size(137, 23);
            this.btnBulkCopy.TabIndex = 9;
            this.btnBulkCopy.Text = "Bulk Copy";
            this.btnBulkCopy.UseVisualStyleBackColor = true;
            this.btnBulkCopy.Click += new System.EventHandler(this.btnBulkCopy_Click);
            // 
            // lblSeparateInsertInfo
            // 
            this.lblSeparateInsertInfo.AutoSize = true;
            this.lblSeparateInsertInfo.Location = new System.Drawing.Point(159, 128);
            this.lblSeparateInsertInfo.Name = "lblSeparateInsertInfo";
            this.lblSeparateInsertInfo.Size = new System.Drawing.Size(323, 13);
            this.lblSeparateInsertInfo.TabIndex = 10;
            this.lblSeparateInsertInfo.Text = "Insert data in separate INSERT statements in the single transaction";
            // 
            // lblTVPInfo
            // 
            this.lblTVPInfo.AutoSize = true;
            this.lblTVPInfo.Location = new System.Drawing.Point(159, 157);
            this.lblTVPInfo.Name = "lblTVPInfo";
            this.lblTVPInfo.Size = new System.Drawing.Size(249, 13);
            this.lblTVPInfo.TabIndex = 11;
            this.lblTVPInfo.Text = "Insert batch of rows using TVP (SQL Server 2008+)";
            // 
            // lblElementCentricXMLInfo
            // 
            this.lblElementCentricXMLInfo.AutoSize = true;
            this.lblElementCentricXMLInfo.Location = new System.Drawing.Point(159, 186);
            this.lblElementCentricXMLInfo.Name = "lblElementCentricXMLInfo";
            this.lblElementCentricXMLInfo.Size = new System.Drawing.Size(302, 13);
            this.lblElementCentricXMLInfo.TabIndex = 12;
            this.lblElementCentricXMLInfo.Text = "Using Element-Cenric XML as parameter parsing it with XQuery";
            // 
            // lblAttributeCentricXMLInfo
            // 
            this.lblAttributeCentricXMLInfo.AutoSize = true;
            this.lblAttributeCentricXMLInfo.Location = new System.Drawing.Point(159, 215);
            this.lblAttributeCentricXMLInfo.Name = "lblAttributeCentricXMLInfo";
            this.lblAttributeCentricXMLInfo.Size = new System.Drawing.Size(303, 13);
            this.lblAttributeCentricXMLInfo.TabIndex = 13;
            this.lblAttributeCentricXMLInfo.Text = "Using Attribute-Cenric XML as parameter parsing it with XQuery";
            // 
            // lblOpenXMLInfo
            // 
            this.lblOpenXMLInfo.AutoSize = true;
            this.lblOpenXMLInfo.Location = new System.Drawing.Point(159, 245);
            this.lblOpenXMLInfo.Name = "lblOpenXMLInfo";
            this.lblOpenXMLInfo.Size = new System.Drawing.Size(154, 13);
            this.lblOpenXMLInfo.TabIndex = 14;
            this.lblOpenXMLInfo.Text = "Using OPENXML to parse data";
            // 
            // lblAttributeCentricTempTableInfo
            // 
            this.lblAttributeCentricTempTableInfo.AutoSize = true;
            this.lblAttributeCentricTempTableInfo.Location = new System.Drawing.Point(159, 283);
            this.lblAttributeCentricTempTableInfo.Name = "lblAttributeCentricTempTableInfo";
            this.lblAttributeCentricTempTableInfo.Size = new System.Drawing.Size(276, 26);
            this.lblAttributeCentricTempTableInfo.TabIndex = 15;
            this.lblAttributeCentricTempTableInfo.Text = "Using Atttribute-Centric XML parsing it with XQuery using \r\ntemporary table to re" +
    "duce locking";
            // 
            // lblSQLBulkCopyInfo
            // 
            this.lblSQLBulkCopyInfo.AutoSize = true;
            this.lblSQLBulkCopyInfo.Location = new System.Drawing.Point(159, 321);
            this.lblSQLBulkCopyInfo.Name = "lblSQLBulkCopyInfo";
            this.lblSQLBulkCopyInfo.Size = new System.Drawing.Size(130, 13);
            this.lblSQLBulkCopyInfo.TabIndex = 16;
            this.lblSQLBulkCopyInfo.Text = "Using SQLBulkCopy class";
            // 
            // lblURL
            // 
            this.lblURL.AutoSize = true;
            this.lblURL.Location = new System.Drawing.Point(548, 393);
            this.lblURL.Name = "lblURL";
            this.lblURL.Size = new System.Drawing.Size(130, 13);
            this.lblURL.TabIndex = 17;
            this.lblURL.TabStop = true;
            this.lblURL.Text = "http://aboutsqlserver.com";
            this.lblURL.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.lblURL_LinkClicked);
            // 
            // labelBookInfo
            // 
            this.labelBookInfo.AutoSize = true;
            this.labelBookInfo.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Italic))), System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.labelBookInfo.Location = new System.Drawing.Point(75, 393);
            this.labelBookInfo.Name = "labelBookInfo";
            this.labelBookInfo.Size = new System.Drawing.Size(223, 13);
            this.labelBookInfo.TabIndex = 18;
            this.labelBookInfo.Text = "PRO SQL Server Internals 2nd Edition";
            // 
            // lblInfo2
            // 
            this.lblInfo2.AutoSize = true;
            this.lblInfo2.Location = new System.Drawing.Point(300, 393);
            this.lblInfo2.Name = "lblInfo2";
            this.lblInfo2.Size = new System.Drawing.Size(249, 13);
            this.lblInfo2.TabIndex = 19;
            this.lblInfo2.Text = "companion materials. Written by Dmitri Korotkevitch";
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(13, 9);
            this.label1.MaximumSize = new System.Drawing.Size(794, 0);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(775, 64);
            this.label1.TabIndex = 20;
            this.label1.Text = resources.GetString("label1.Text");
            this.label1.TextAlign = System.Drawing.ContentAlignment.TopCenter;
            // 
            // lblSiResult
            // 
            this.lblSiResult.AutoSize = true;
            this.lblSiResult.ForeColor = System.Drawing.Color.Red;
            this.lblSiResult.Location = new System.Drawing.Point(520, 128);
            this.lblSiResult.Name = "lblSiResult";
            this.lblSiResult.Size = new System.Drawing.Size(0, 13);
            this.lblSiResult.TabIndex = 21;
            // 
            // lblTVPResult
            // 
            this.lblTVPResult.AutoSize = true;
            this.lblTVPResult.ForeColor = System.Drawing.Color.Red;
            this.lblTVPResult.Location = new System.Drawing.Point(520, 157);
            this.lblTVPResult.Name = "lblTVPResult";
            this.lblTVPResult.Size = new System.Drawing.Size(0, 13);
            this.lblTVPResult.TabIndex = 22;
            // 
            // lblECXMLResult
            // 
            this.lblECXMLResult.AutoSize = true;
            this.lblECXMLResult.ForeColor = System.Drawing.Color.Red;
            this.lblECXMLResult.Location = new System.Drawing.Point(520, 186);
            this.lblECXMLResult.Name = "lblECXMLResult";
            this.lblECXMLResult.Size = new System.Drawing.Size(0, 13);
            this.lblECXMLResult.TabIndex = 23;
            // 
            // lblACXMLResult
            // 
            this.lblACXMLResult.AutoSize = true;
            this.lblACXMLResult.ForeColor = System.Drawing.Color.Red;
            this.lblACXMLResult.Location = new System.Drawing.Point(520, 215);
            this.lblACXMLResult.Name = "lblACXMLResult";
            this.lblACXMLResult.Size = new System.Drawing.Size(0, 13);
            this.lblACXMLResult.TabIndex = 24;
            // 
            // lblOXMLResult
            // 
            this.lblOXMLResult.AutoSize = true;
            this.lblOXMLResult.ForeColor = System.Drawing.Color.Red;
            this.lblOXMLResult.Location = new System.Drawing.Point(520, 245);
            this.lblOXMLResult.Name = "lblOXMLResult";
            this.lblOXMLResult.Size = new System.Drawing.Size(0, 13);
            this.lblOXMLResult.TabIndex = 25;
            // 
            // lblACTTXMLResult
            // 
            this.lblACTTXMLResult.AutoSize = true;
            this.lblACTTXMLResult.ForeColor = System.Drawing.Color.Red;
            this.lblACTTXMLResult.Location = new System.Drawing.Point(520, 283);
            this.lblACTTXMLResult.Name = "lblACTTXMLResult";
            this.lblACTTXMLResult.Size = new System.Drawing.Size(0, 13);
            this.lblACTTXMLResult.TabIndex = 26;
            // 
            // lblBCResult
            // 
            this.lblBCResult.AutoSize = true;
            this.lblBCResult.ForeColor = System.Drawing.Color.Red;
            this.lblBCResult.Location = new System.Drawing.Point(520, 321);
            this.lblBCResult.Name = "lblBCResult";
            this.lblBCResult.Size = new System.Drawing.Size(0, 13);
            this.lblBCResult.TabIndex = 27;
            // 
            // lblJSON
            // 
            this.lblJSON.AutoSize = true;
            this.lblJSON.Location = new System.Drawing.Point(159, 350);
            this.lblJSON.Name = "lblJSON";
            this.lblJSON.Size = new System.Drawing.Size(156, 13);
            this.lblJSON.TabIndex = 29;
            this.lblJSON.Text = "Using JSON (SQL Server 2016)";
            // 
            // btnJSON
            // 
            this.btnJSON.Location = new System.Drawing.Point(16, 345);
            this.btnJSON.Name = "btnJSON";
            this.btnJSON.Size = new System.Drawing.Size(137, 23);
            this.btnJSON.TabIndex = 28;
            this.btnJSON.Text = "JSON";
            this.btnJSON.UseVisualStyleBackColor = true;
            this.btnJSON.Click += new System.EventHandler(this.btnJSON_Click);
            // 
            // lblJSONResult
            // 
            this.lblJSONResult.AutoSize = true;
            this.lblJSONResult.ForeColor = System.Drawing.Color.Red;
            this.lblJSONResult.Location = new System.Drawing.Point(520, 345);
            this.lblJSONResult.Name = "lblJSONResult";
            this.lblJSONResult.Size = new System.Drawing.Size(0, 13);
            this.lblJSONResult.TabIndex = 30;
            // 
            // MainForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(814, 414);
            this.Controls.Add(this.lblJSONResult);
            this.Controls.Add(this.lblJSON);
            this.Controls.Add(this.btnJSON);
            this.Controls.Add(this.lblBCResult);
            this.Controls.Add(this.lblACTTXMLResult);
            this.Controls.Add(this.lblOXMLResult);
            this.Controls.Add(this.lblACXMLResult);
            this.Controls.Add(this.lblECXMLResult);
            this.Controls.Add(this.lblTVPResult);
            this.Controls.Add(this.lblSiResult);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.lblInfo2);
            this.Controls.Add(this.labelBookInfo);
            this.Controls.Add(this.lblURL);
            this.Controls.Add(this.lblSQLBulkCopyInfo);
            this.Controls.Add(this.lblAttributeCentricTempTableInfo);
            this.Controls.Add(this.lblOpenXMLInfo);
            this.Controls.Add(this.lblAttributeCentricXMLInfo);
            this.Controls.Add(this.lblElementCentricXMLInfo);
            this.Controls.Add(this.lblTVPInfo);
            this.Controls.Add(this.lblSeparateInsertInfo);
            this.Controls.Add(this.btnBulkCopy);
            this.Controls.Add(this.tbConnString);
            this.Controls.Add(this.btnAttributeCentricTempTable);
            this.Controls.Add(this.btnOpenXml);
            this.Controls.Add(this.btnAttributeCentric);
            this.Controls.Add(this.btnElementCentric);
            this.Controls.Add(this.btnTvp);
            this.Controls.Add(this.btnSeparateInserts);
            this.Controls.Add(this.tbPacketSize);
            this.Controls.Add(this.lblPacketSize);
            this.MaximizeBox = false;
            this.Name = "MainForm";
            this.Text = "Saving Batch of Rows";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label lblPacketSize;
        private System.Windows.Forms.TextBox tbPacketSize;
        private System.Windows.Forms.Button btnSeparateInserts;
        private System.Windows.Forms.Button btnTvp;
		private System.Windows.Forms.Button btnElementCentric;
		private System.Windows.Forms.Button btnAttributeCentric;
		private System.Windows.Forms.Button btnOpenXml;
        private System.Windows.Forms.Button btnAttributeCentricTempTable;
        private System.Windows.Forms.TextBox tbConnString;
        private System.Windows.Forms.Button btnBulkCopy;
        private System.Windows.Forms.Label lblSeparateInsertInfo;
        private System.Windows.Forms.Label lblTVPInfo;
        private System.Windows.Forms.Label lblElementCentricXMLInfo;
        private System.Windows.Forms.Label lblAttributeCentricXMLInfo;
        private System.Windows.Forms.Label lblOpenXMLInfo;
        private System.Windows.Forms.Label lblAttributeCentricTempTableInfo;
        private System.Windows.Forms.Label lblSQLBulkCopyInfo;
        private System.Windows.Forms.LinkLabel lblURL;
        private System.Windows.Forms.Label labelBookInfo;
        private System.Windows.Forms.Label lblInfo2;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label lblSiResult;
        private System.Windows.Forms.Label lblTVPResult;
        private System.Windows.Forms.Label lblECXMLResult;
        private System.Windows.Forms.Label lblACXMLResult;
        private System.Windows.Forms.Label lblOXMLResult;
        private System.Windows.Forms.Label lblACTTXMLResult;
        private System.Windows.Forms.Label lblBCResult;
        private System.Windows.Forms.Label lblJSON;
        private System.Windows.Forms.Button btnJSON;
        private System.Windows.Forms.Label lblJSONResult;
    }
}

