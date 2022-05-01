/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                          Chapter 09. Triggers                            */
/*                              DDL Triggers                                */
/****************************************************************************/

use [SqlServerInternals]
go

if exists(select * from sys.triggers where name = 'trg_PreventAlterDropTable') drop trigger trg_PreventAlterDropTable on database;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'Test') drop table dbo.Test;
go

create table dbo.Test(ID int);
go

create trigger trg_PreventAlterDropTable on database
for alter_table, drop_table
as
begin
    declare
        @objName nvarchar(257);
	select @objName =   
            eventdata().value('/EVENT_INSTANCE[1]/SchemaName[1]','nvarchar(128)') + 
                '.' + eventdata().value('/EVENT_INSTANCE[1]/ObjectName[1]','nvarchar(128)');

    select column_id, name 
    from sys.columns 
    where object_id = object_id(@objName);
	
    print 'Table cannot be altered or dropped with trgPreventAlterDropTable trigger enabled' 
    rollback;
end
go

-- Failed
alter table dbo.Test add Col1 int;
go

-- Clean-up
drop trigger trg_PreventAlterDropTable on database;
go

