/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Chapter 11: Utilizing In-Memory OLTP                     */
/*           11.Evaluating Performance of Natively Compiled SPs             */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

if object_id(N'dbo.CalcDistance','FN') is not null drop function dbo.CalcDistance;
if object_id(N'dbo.CalcDistanceInline','IF') is not null drop function dbo.CalcDistanceInline;
if object_id(N'dbo.CalcDistanceCLR','FS') is not null drop function dbo.CalcDistanceCLR;
if exists(select * from sys.assemblies where name = 'InMemOLTPBoxCLR') drop assembly InMemOLTPBoxCLR;
if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'CalcDistanceInMem') drop proc dbo.CalcDistanceInMem; 
go

create function dbo.CalcDistance
(
	@LoopCnt int
	,@FromLat decimal(9,6)
	,@FromLon decimal(9,6)
	,@ToLat decimal(9,6)
	,@ToLon decimal(9,6)
)
returns float
with schemabinding
as 
begin
	declare	
		@Dist float
		,@Loop int = 0
		,@FromLatR float
		,@FromLonR float
		,@ToLatR float
		,@ToLonR float

	while @Loop < @LoopCnt
	begin
		select 
			@FromLatR = radians(@FromLat)
			,@FromLonR = radians(@FromLon)
			,@ToLatR = radians(@ToLat)
			,@ToLonR = radians(@ToLon)

		set @Dist = 
			2 * asin(
				sqrt(
					power(sin( (@FromLatR - @ToLatR) / 2.), 2) + 
	 				(
						cos(@FromLatR) * 
						cos(@ToLatR) * 
						power(sin((@FromLonR - @ToLonR) / 2.0), 2)
					)
				)
			) * 20001600. / pi()
		select @Loop += 1;
	end	
	return @Dist
end;
go

create proc dbo.CalcDistanceInMem
(
	@LoopCnt int
	,@FromLat decimal(9,6)
	,@FromLon decimal(9,6)
	,@ToLat decimal(9,6)
	,@ToLon decimal(9,6)
	,@Dist float output
)
with native_compilation, schemabinding, execute as owner
as
begin atomic with
(
    transaction isolation level = snapshot
    ,language = N'English'
)
	declare	
		@Loop int = 0
		,@FromLatR float
		,@FromLonR float
		,@ToLatR float
		,@ToLonR float

	while @Loop < @LoopCnt
	begin
		select 
			@FromLatR = radians(@FromLat)
			,@FromLonR = radians(@FromLon)
			,@ToLatR = radians(@ToLat)
			,@ToLonR = radians(@ToLon)

		set @Dist = 
			2 * asin(
				sqrt(
					power(sin( (@FromLatR - @ToLatR) / 2.), 2) + 
	 				(
						cos(@FromLatR) * 
						cos(@ToLatR) * 
						power(sin((@FromLonR - @ToLonR) / 2.0), 2)
					)
				)
			) * 20001600. / pi()
		select @Loop += 1;
	end	
end;
go

/* One call - multiple loops inside */
declare
	@Result float 
	,@LoopCnt int = 10000
	,@DT datetime

select @DT = getdate();
select @Result = dbo.CalcDistance(@LoopCnt,28,-82,29,-83);
select datediff(millisecond,@DT,GetDate()) as [T-SQL Function];
go

declare
	@Result float 
	,@LoopCnt int = 10000
	,@DT datetime

select @DT = getdate();
exec dbo.CalcDistanceInMem @LoopCnt,28,-82,29,-83, @Result output
select datediff(millisecond,@DT,GetDate()) as [Natively Compiled Proc];
go

/* Multiple Calls in the Loop */
declare
	@Result float 
	,@LoopCnt int = 10000
	,@DT datetime
	,@I int = 0

select @DT = getdate();
while @I < @LoopCnt
begin
	select @Result = dbo.CalcDistance(1,28,-82,29,-83);
	select @I += 1;
end
select datediff(millisecond,@DT,GetDate()) as [T-SQL Function];
go

declare
	@Result float 
	,@LoopCnt int = 10000
	,@DT datetime
	,@I int = 0

select @DT = getdate();
while @I < @LoopCnt
begin
	exec dbo.CalcDistanceInMem 1,28,-82,29,-83, @Result output
	select @I += 1;
end
select datediff(millisecond,@DT,GetDate()) as [Natively Compiled Proc];
go


/* Let's check performance of Inline Function */
create function dbo.CalcDistanceInline
(
	@FromLat decimal(9,6)
	,@FromLon decimal(9,6)
	,@ToLat decimal(9,6)
	,@ToLon decimal(9,6)
)
returns table
as
return
(
	with Rads(FromLatR, FromLonR, ToLatR, ToLonR)
	as 
	 (
		select 
			radians(@FromLat), radians(@FromLon),
			radians(@ToLat), radians(@ToLon)
	)
	select	
		2 * asin(
			sqrt(
				power(sin((FromLatR - ToLatR) / 2.), 2) + 
	 			(
					cos(FromLatR) * 
					cos(ToLatR) * 
					power(sin((FromLonR - ToLonR) / 2.0),2)
				)
			)
		) * 20001600. / pi() as Distance
	   from Rads
);
go

declare
	@Result float 
	,@LoopCnt int = 10000
	,@DT datetime
	,@I int = 0

select @DT = getdate();
while @I < @LoopCnt
begin
	exec dbo.CalcDistanceInMem 1,28,-82,29,-83, @Result output
	select @I += 1;
end
select datediff(millisecond,@DT,GetDate()) as [Natively Compiled Proc];
go


declare
	@Result float 
	,@LoopCnt int = 10000
	,@DT datetime
	,@I int = 0

select @DT = getdate();
while @I < @LoopCnt
begin
	select @Result = Distance
	from dbo.CalcDistanceInline(28,-82,29,-83);
	select @I += 1;
end
select datediff(millisecond,@DT,GetDate()) as [Inline Function];
go


create assembly [InMemOLTPBoxCLR]
authorization [dbo]
from 0x4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F742062652072756E20696E20444F53206D6F64652E0D0D0A2400000000000000504500004C0103007AEAE1550000000000000000E00002210B010B00000A00000006000000000000DE2900000020000000400000000000100020000000020000040000000000000004000000000000000080000000020000000000000300408500001000001000000000100000100000000000001000000000000000000000008C2900004F00000000400000C002000000000000000000000000000000000000006000000C000000542800001C0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002E74657874000000E409000000200000000A000000020000000000000000000000000000200000602E72737263000000C00200000040000000040000000C0000000000000000000000000000400000402E72656C6F6300000C0000000060000000020000001000000000000000000000000000004000004200000000000000000000000000000000C02900000000000048000000020005002022000034060000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013300200AE0000000100001100166A0A0F00280500000A2D230F01280500000A2D1A0F00280600000A1632100F00280600000A1F5DFE0216FE012B011600130611062D097E0700000A13052B6A160D2B4C000F00280600000A17FE0216FE01130611062D3000176A0A166A0B1813042B1000060C0607580A080B0011041758130411040F00280600000AFE04130611062DDF002B03166A0A000917580D090F01280600000AFE04130611062DA406730800000A13052B0011052A000013300500FF0000000200001100230000000000000000130416130538C90000000023399D52A246DF913F0F01280900000A5A0A23399D52A246DF913F0F02280900000A5A0B23399D52A246DF913F0F03280900000A5A0C23399D52A246DF913F0F04280900000A5A0D2300000000000000400608592300000000000000405B280A00000A230000000000000040280B00000A06280C00000A08280C00000A5A0709592300000000000000405B280A00000A230000000000000040280B00000A5A58280D00000A280E00000A5A2300000000341373415A23182D4454FB2109405B13040011051758130511050F00280600000AFE04130711073A23FFFFFF1104730F00000A13062B0011062A1E02281000000A2A0042534A4201000100000000000C00000076322E302E35303732370000000005006C000000B8010000237E000024020000E001000023537472696E6773000000000404000008000000235553000C0400001000000023475549440000001C0400001802000023426C6F620000000000000002000001471502000900000000FA253300160000010000000A000000020000000300000007000000100000000500000002000000010000000200000000000A00010000000000060043003C000A006B0056000A00740056000A008E0056000600E700D4001700FB00000006002A010A0106004A010A010A00930178010600C2013C000000000001000000000001000100010010001E00000005000100010050200000000096007D000A0001000C210000000096009800130003001722000000008618A8002200080000000100AE0000000200B00000000100B00000000200B80000000300C00000000400C80000000500CE002900A80026003900A8002C004100A80022004900A80022001900A801EE001900B301F2001100BD01F6001100A800FA002100B301C7015100C701CB015100CB01D0015100CF01CB015100D301CB015100D801CB012100A800D6010900A80022002000230031002E000B00E7012E001300F0012E001B00F901400023000A01FF00DB0104800000000000000000000000000000000068010000020000000000000000000000010033000000000002000000000000000000000001004A00000000000000003C4D6F64756C653E00496E4D656D4F4C5450426F78434C522E646C6C0055736572446566696E656446756E6374696F6E73006D73636F726C69620053797374656D004F626A6563740053797374656D2E446174610053797374656D2E446174612E53716C54797065730053716C496E7436340053716C496E7433320043616C634669626F6E61636369434C520053716C446F75626C650043616C6344697374616E6365434C52002E63746F72004E006C6F6F70436E740066726F6D4C61740066726F6D4C6F6E00746F4C617400746F4C6F6E0053797374656D2E446961676E6F73746963730044656275676761626C6541747472696275746500446562756767696E674D6F6465730053797374656D2E52756E74696D652E436F6D70696C6572536572766963657300436F6D70696C6174696F6E52656C61786174696F6E734174747269627574650052756E74696D65436F6D7061746962696C69747941747472696275746500496E4D656D4F4C5450426F78434C52004D6963726F736F66742E53716C5365727665722E5365727665720053716C46756E6374696F6E417474726962757465006765745F49734E756C6C006765745F56616C7565004E756C6C004D6174680053696E00506F7700436F730053717274004173696E00000000000320000000000054FCAFBBB51DD240ABDAA1B0D8FDF0790008B77A5C561934E0890800021109110D110D0E00051111110D111111111111111103200001052001011119042001010880BB0100030054020F497344657465726D696E6973746963015402094973507265636973650154557F4D6963726F736F66742E53716C5365727665722E5365727665722E53797374656D446174614163636573734B696E642C2053797374656D2E446174612C2056657273696F6E3D322E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D623737613563353631393334653038391053797374656D4461746141636365737300000000032000020320000803061109042001010A0A07070A0A0A080811090280BB0100030054020F497344657465726D696E6973746963015402094973507265636973650054557F4D6963726F736F66742E53716C5365727665722E5365727665722E53797374656D446174614163636573734B696E642C2053797374656D2E446174612C2056657273696F6E3D322E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D623737613563353631393334653038391053797374656D44617461416363657373000000000320000D0400010D0D0500020D0D0D042001010D0B07080D0D0D0D0D081111020801000701000000000801000800000000001E01000100540216577261704E6F6E457863657074696F6E5468726F777301000000007AEAE15500000000020000001C01000070280000700A0000525344531ABC26750F384947BE11DC9A60B2468702000000653A5C576F726B5C576F726B5C56535C496E4D656D4F4C5450426F785C434C525C6F626A5C44656275675C496E4D656D4F4C5450426F78434C522E706462000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000B42900000000000000000000CE290000002000000000000000000000000000000000000000000000C0290000000000000000000000005F436F72446C6C4D61696E006D73636F7265652E646C6C0000000000FF25002000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058400000640200000000000000000000640234000000560053005F00560045005200530049004F004E005F0049004E0046004F0000000000BD04EFFE00000100000000000000000000000000000000003F000000000000000400000002000000000000000000000000000000440000000100560061007200460069006C00650049006E0066006F00000000002400040000005400720061006E0073006C006100740069006F006E00000000000000B004C4010000010053007400720069006E006700460069006C00650049006E0066006F000000A001000001003000300030003000300034006200300000002C0002000100460069006C0065004400650073006300720069007000740069006F006E000000000020000000300008000100460069006C006500560065007200730069006F006E000000000030002E0030002E0030002E003000000048001400010049006E007400650072006E0061006C004E0061006D006500000049006E004D0065006D004F004C005400500042006F00780043004C0052002E0064006C006C0000002800020001004C006500670061006C0043006F0070007900720069006700680074000000200000005000140001004F0072006900670069006E0061006C00460069006C0065006E0061006D006500000049006E004D0065006D004F004C005400500042006F00780043004C0052002E0064006C006C000000340008000100500072006F006400750063007400560065007200730069006F006E00000030002E0030002E0030002E003000000038000800010041007300730065006D0062006C0079002000560065007200730069006F006E00000030002E0030002E0030002E0030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000C000000E03900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
go

create function [dbo].[CalcDistanceCLR]
(@loopCnt int, @fromLat float, @fromLon float, @toLat float, @toLon float)
returns float
as
	external name [InMemOLTPBoxCLR].[UserDefinedFunctions].[CalcDistanceCLR];
go

/****************************************************************************
[Microsoft.SqlServer.Server.SqlFunction(
    IsDeterministic = true, IsPrecise = false,
    SystemDataAccess = SystemDataAccessKind.None)]
public static SqlDouble CalcDistanceCLR
(
	SqlInt32 loopCnt,
    SqlDouble fromLat, SqlDouble fromLon,
    SqlDouble toLat, SqlDouble toLon
)
{
    double fromLatR, fromLonR, toLatR, toLonR, result = 0;

    for (int i = 0; i < loopCnt.Value; i++)
    {
        fromLatR = Math.PI / 180 * fromLat.Value;
        fromLonR = Math.PI / 180 * fromLon.Value;
        toLatR = Math.PI / 180 * toLat.Value;
        toLonR = Math.PI / 180 * toLon.Value;
        result =
            2 * Math.Asin(
                Math.Sqrt(
                    Math.Pow(Math.Sin((fromLatR - toLatR) / 2.0), 2) +
                    (
                         Math.Cos(fromLatR) * Math.Cos(toLatR) *
                         Math.Pow(Math.Sin((fromLonR - toLonR) / 2.0), 2)
                    )
            )) * 20001600.0 / Math.PI;
    };
    return new SqlDouble(result);
}
****************************************************************************/

declare
	@Result float 
	,@LoopCnt int = 10000
	,@DT datetime
	,@I int = 0

select @DT = getdate();
while @I < @LoopCnt
begin
	exec dbo.CalcDistanceInMem 1,28,-82,29,-83, @Result output
	select @I += 1;
end
select datediff(millisecond,@DT,GetDate()) as [Natively Compiled Proc];
go

declare
	@Result float 
	,@LoopCnt int = 10000
	,@DT datetime
	,@I int = 0

select @DT = getdate();
while @I < @LoopCnt
begin
	select @Result =  dbo.CalcDistanceCLR(1,28,-82,29,-83)
	select @I += 1;
end
select datediff(millisecond,@DT,GetDate()) as [CLR Proc];
go