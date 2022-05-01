/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*         02.Splitting Data (Addressing 8,060-byte row size limit)         */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if object_id(N'dbo.SplitData','IF') is not null drop function dbo.SplitData; 
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'LOBData') drop table dbo.LOBData; 
go

create table dbo.LOBData
(
    ObjectId int not null,
    PartNo smallint not null,
    Data varbinary(8000) not null,

    constraint PK_LobData
    primary key nonclustered hash(ObjectID, PartNo)
    with (bucket_count=1048576),

    index IDX_ObjectID
    nonclustered hash(ObjectID)
    with (bucket_count=1048576)
)
with (memory_optimized = on, durability = schema_and_data);
go

create function dbo.SplitData
(
    @LobData varbinary(max)
)
returns table
as
return
(
    with Parts(Start, Data)
    as
    (
        select 1, substring(@LobData,1,8000) 
        where @LobData is not null
		
        union all
		
        select Start + 8000, substring(@LobData,Start + 8000,8000)
        from Parts
        where len(substring(@LobData,Start + 8000,8000)) > 0
    )
    select 
        row_number() over(order by Start) as PartNo
        ,Data
    from
        Parts
)
go

declare
    @X xml

select @X = 
    (select * from master.sys.objects for xml raw);

insert into dbo.LobData(ObjectId, PartNo, Data)
    select 1, PartNo, Data
    from dbo.SplitData(convert(varbinary(max),@X))
-- option (maxrecursion 0);
go

select ObjectId, PartNo, Data 
from dbo.LobData 
where ObjectId = 1
order by PartNo;
go

;with ConcatData(BinaryData)
as
(
    select 
        convert(varbinary(max),
            (
                select convert(varchar(max),Data,2) as [text()]
                from dbo.LobData
                where ObjectId = 1
                order by PartNo
                for xml path('')
            ),2)
)
select convert(xml,BinaryData) 
from ConcatData;
