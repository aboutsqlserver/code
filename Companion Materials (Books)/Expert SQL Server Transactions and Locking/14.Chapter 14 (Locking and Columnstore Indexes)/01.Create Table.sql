/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*               Chapter 14. Locking and Columnstore Indexes                */
/*                           Creating Table                                 */
/****************************************************************************/
set noexec off
go

use SQLServerInternals
go

declare
	@EngineEdition int = convert(int, serverproperty('EngineEdition')) -- 3 means Enterprise
	,@EngineVersion int = convert(int,
			left(
				convert(nvarchar(128), serverproperty('ProductVersion')),
				charindex('.',convert(nvarchar(128), serverproperty('ProductVersion'))) - 1
			)
	) 

if 
	not
	(
		(
			(@EngineEdition = 3) and -- Enterprise / Developer
			(@EngineVersion >= 13) -- SQL Server 2016+
		)
		or 
		(
			(@EngineVersion > 13) -- SQL Server 2017+
		)
		or
		(
			(@EngineVersion = 13) -- SQL Server 2016
			and 
			left(convert(varchar(64),serverproperty('productlevel')),2) = 'SP'
		) -- SQL Server 2016 with SP	
	)
begin
	raiserror('SQL Server version does not support Columnstore Indexes',0,1) with nowait;
	set noexec on
end
go

drop table if exists dbo.Test;
go

create table dbo.Test
(
	ID int not null,
	Col int not null
)
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2 ) -- 65,536 rows
,N6(C) AS (select 0 from N5 as T1 cross join N3 as T2 cross join N2 as T3) -- 4,194,304 rows
,IDs(ID) as (select row_number() over (order by (select null)) from N6)
insert into dbo.Test(ID, Col)
	select ID, ID from IDs;
go

create clustered columnstore index CCI_Test
on dbo.Test
with (maxdop = 1);
go

select * 
from sys.column_store_row_groups 
where object_id = object_id(N'dbo.Test');
go
