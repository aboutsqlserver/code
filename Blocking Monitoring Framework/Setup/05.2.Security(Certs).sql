/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                              Initial Setup                               */
/*                            Setting Up Security                           */
/****************************************************************************/


-- Certificate-based security. Do not forget to re-sign activation stored procedures
-- when you alter them and/or upgrade the framework

use master
go

if exists(select * from sys.server_principals where name = 'BMFrameworkLogin' and type = 'C') drop login BMFrameworkLogin;
if exists(select * from sys.certificates where name = 'BMFrameworkCert') drop certificate BMFrameworkCert;
go

use DBA
go

if exists(select * from sys.crypt_properties where major_id = object_id(N'dbo.SB_BlockedProcessReport_Activation') and crypt_type = 'SPVC') drop signature from dbo.SB_BlockedProcessReport_Activation by certificate BMFrameworkCert;
if exists(select * from sys.crypt_properties where major_id = object_id(N'dbo.SB_DeadlockEvent_Activation') and crypt_type = 'SPVC') drop signature from dbo.SB_DeadlockEvent_Activation by certificate BMFrameworkCert;
if exists(select * from sys.database_principals	where name = 'EventMonitoringUser' and type = 'S') drop user EventMonitoringUser;
if exists(select * from sys.certificates where name = 'BMFrameworkCert') drop certificate BMFrameworkCert;
go

if not exists 
(
	select * 
	from sys.symmetric_keys 
	where symmetric_key_id = 101
)
	create master key encryption 
	by password = 'Pas$word1'; -- Use Strong Password instead
go

create certificate BMFrameworkCert 
with subject = 'Cert for event monitoring', 
expiry_date = '20301031';
go

-- We need to re-sign every time we alter 
-- the stored procedure
add signature to dbo.SB_BlockedProcessReport_Activation
by certificate BMFrameworkCert;
go

add signature to dbo.SB_DeadlockEvent_Activation
by certificate BMFrameworkCert;
go

backup certificate BMFrameworkCert
to file='BMFrameworkCert.cer';
go

use master
go

create certificate BMFrameworkCert
from file='BMFrameworkCert.cer';
go

create login BMFrameworkLogin
from certificate BMFrameworkCert;
go

grant view server state, 
	authenticate server to BMFrameworkLogin;
go
