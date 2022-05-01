/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                            Chapter 13. CLR                               */
/*                  Creating Objects for Chapter' Scripts                   */
/****************************************************************************/

set noexec off
go

set nocount on
go

use [SqlServerInternals]
go

/*** Checking if CLR is not enabled ***/
if not exists
(
	select * 
	from sys.configurations 
	where name = 'clr enabled' and value = 1
)
begin
	raiserror('CLR Integration is not enabled.',16,1) with nowait
	raiserror('You can enable it in SQL Server Surface Area Configuration Utility',0,1) with nowait
	set noexec on
end

if exists (select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Numbers' and s.name = 'dbo') drop table dbo.Numbers;
if exists (select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'AddressesCLR' and s.name = 'dbo') drop table dbo.AddressesCLR;
if exists (select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where	s.name = 'dbo' and p.name = 'ExistInInterval') drop proc dbo.ExistInInterval;
if exists (select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where	s.name = 'dbo' and p.name = 'ExistInIntervalCursor') drop proc dbo.ExistInIntervalCursor;
if exists (select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where	s.name = 'dbo' and p.name = 'EndlessLoop') drop proc dbo.EndlessLoop;
if exists (select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where	s.name = 'dbo' and p.name = 'ExistInIntervalCLR') drop proc dbo.ExistInIntervalCLR;
if exists (select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where	s.name = 'dbo' and p.name = 'ExistInIntervalReaderCLR') drop proc dbo.ExistInIntervalReaderCLR;
if object_id(N'[dbo].[Concatenate]') is not null drop aggregate dbo.Concatenate;
if object_id(N'[dbo].[EvenNumberCLR]') is not null drop function [dbo].[EvenNumberCLR];
if object_id(N'[dbo].[EvenNumberCLRWithDataAccess]') is not null drop function [dbo].EvenNumberCLRWithDataAccess;
if object_id(N'[dbo].[CalcDistance]') is not null drop function [dbo].CalcDistance;
if object_id(N'[dbo].[CalcDistanceCLR]') is not null drop function [dbo].CalcDistanceCLR;
if object_id(N'[dbo].[CalcDistanceInline]') is not null drop function [dbo].CalcDistanceInline;
if object_id(N'[dbo].[EvenNumber]') is not null drop function [dbo].[EvenNumber];
if object_id(N'[dbo].[EvenNumberInline]') is not null drop function [dbo].EvenNumberInline;
if object_id(N'[dbo].[LikeCLR]') is not null drop function [dbo].[LikeCLR];
if object_id(N'[dbo].[CalcCircleBoundingBox]') is not null drop function [dbo].CalcCircleBoundingBox;
if exists (select * from sys.types t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'USPostalAddress' and s.name = 'dbo') drop type dbo.USPostalAddress;
if exists (select * from sys.assemblies where name = 'CLRTest') drop assembly CLRTest;
go

/*** Creating assembly from byte-sequence. You can compile and register DLL instead ***/
create assembly CLRTest
from
0x4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F742062652072756E20696E20444F53206D6F64652E0D0D0A2400000000000000504500004C01030017186D530000000000000000E00002210B010B00002C00000006000000000000FE49000000200000006000000000001000200000000200000400000000000000040000000000000000A000000002000000000000030040850000100000100000000010000010000000000000100000000000000000000000B04900004B00000000600000A002000000000000000000000000000000000000008000000C000000784800001C0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002E74657874000000042A000000200000002C000000020000000000000000000000000000200000602E72737263000000A00200000060000000040000002E0000000000000000000000000000400000402E72656C6F6300000C0000000080000000020000003200000000000000000000000000004000004200000000000000000000000000000000E0490000000000004800000002000500E82D0000901A00000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000133002002E00000001000011000218280600000A280700000A16280600000A280800000A280900000A2D03162B011700730A00000A0A2B00062A0000133002002E00000001000011000218280600000A280700000A16280600000A280800000A280900000A2D03162B011700730A00000A0A2B00062A000013300500CC000000020000110023399D52A246DF913F0F00280B00000A5A0A23399D52A246DF913F0F01280B00000A5A0B23399D52A246DF913F0F02280B00000A5A0C23399D52A246DF913F0F03280B00000A5A0D2300000000000000400608592300000000000000405B280C00000A230000000000000040280D00000A06280E00000A08280E00000A5A0709592300000000000000405B280C00000A230000000000000040280D00000A5A58280F00000A281000000A5A2300000000341373415A23182D4454FB2109405B731100000A13042B0011042A1330020052000000030000110002A5030000020A0312007B01000004731100000A81060000010412007B02000004731100000A81060000010512007B03000004731100000A81060000010E0412007B04000004731100000A81060000012A000013300400AF03000004000011000F00281200000A2D150F01281200000A2D0C0F02281300000A16FE012B011600131711172D08141316387D030000178D030000020A23399D52A246DF913F0F00280B00000A5A0B23399D52A246DF913F0F01280B00000A5A0C23182D4454FB21E93F0D23D221337F7CD902401304235E3855297A6A0F4013052375A7BBE9BBFD154013060F02281400000A6C23E33B7F669EA0F63F5A23182D4454FB2109405A2300000000341373415B130707280C00000A1107280E00000A5A07280E00000A1107280C00000A5A09280E00000A5A58281000000A130807280C00000A1107280E00000A5A07280E00000A1107280C00000A5A1104280E00000A5A58281000000A130907280C00000A1107280E00000A5A07280E00000A1107280C00000A5A1105280E00000A5A58281000000A130A07280C00000A1107280E00000A5A07280E00000A1107280C00000A5A1106280E00000A5A58281000000A130B09280C00000A1107280C00000A5A07280E00000A5A1107280E00000A07280C00000A1108280C00000A5A59281500000A130C1104280C00000A1107280C00000A5A07280E00000A5A1107280E00000A07280C00000A1109280C00000A5A59281500000A130D1105280C00000A1107280C00000A5A07280E00000A5A1107280E00000A07280C00000A110A280C00000A5A59281500000A130E1106280C00000A1107280C00000A5A07280E00000A5A1107280E00000A07280C00000A110B280C00000A5A59281500000A130F11082300000000008066405A23182D4454FB2109405B1310110A2300000000008066405A23182D4454FB2109405B131108110C5923182D4454FB2109405823182D4454FB2119405D23182D4454FB210940592300000000008066405A23182D4454FB2109405B131208110D5923182D4454FB2109405823182D4454FB2119405D23182D4454FB210940592300000000008066405A23182D4454FB2109405B131308110E5923182D4454FB2109405823182D4454FB2119405D23182D4454FB210940592300000000008066405A23182D4454FB2109405B131408110F5923182D4454FB2109405823182D4454FB2119405D23182D4454FB210940592300000000008066405A23182D4454FB2109405B131506168F0300000211101111281600000A7D0100000406168F0300000211101111281700000A7D0200000406168F0300000211121113281600000A11141115281600000A281600000A7D0300000406168F0300000211121113281700000A11141115281700000A281700000A7D040000040613162B0011162A1E02281800000A2A360002731C00000A7D050000042A000000133002002C00000005000011000F01281D00000A16FE010A062D022B1A027B050000040F01281E00000A6F1F00000A1F2C6F2000000A262A5200027B05000004037B050000046F2100000A262A000000133004004F00000006000011007E2200000A0A027B050000042C13027B050000046F2300000A16FE0216FE012B0117000C082D1C00027B0500000416027B050000046F2300000A17596F2400000A0A0006732500000A0B2B00072A4E0002036F2600000A732700000A7D050000042A520003027B050000046F2800000A6F2900000A002A1E02281800000A2A1B300300D10000000700001100160A7201000070732B00000A0B00076F2C00000A00723100007007732D00000A0C086F2E00000A72C00100701E6F2F00000A186F3000000A00086F2E00000A72D00100701E6F2F00000A260F00281400000A0D2B4500086F2E00000A176F3100000A098C240000016F3200000A00086F3300000A2606086F2E00000A166F3100000A6F3400000AA524000001580A16283500000A00000917580D090F01281400000AFE0216FE01130411042DA800DE120714FE01130411042D07076F3600000A00DC000406730A00000A81050000012A0000000110000002000E00A3B10012000000001B300300CB0000000800001100160A7201000070732B00000A0B00076F2C00000A0072E001007007732D00000A0C086F2E00000A72990200701E6F2F00000A028C050000016F3200000A00086F2E00000A72A70200701E6F2F00000A038C050000016F3200000A00086F3700000A0D002B20000617580A0620F40100005D16FE0116FE01130411042D0716283500000A0000096F3800000A130411042DD400DE120914FE01130411042D07096F3600000A00DC0000DE120714FE01130411042D07076F3600000A00DC000406730A00000A81050000012A00011C000002006300329500120000000002000E009DAB001200000000133001000700000005000011002B00170A2BFC1E02281800000A2A00133001000C0000000500001100027B070000040A2B00062A133001000C0000000900001100027B080000040A2B00062A133001000C0000000900001100027B090000040A2B00062A133001000C0000000900001100027B0A0000040A2B00062A133001000C0000000900001100027B0B0000040A2B00062A133004003C0000000A0000110072B50200701A8D010000010B0716027B08000004A20717027B09000004A20718027B0A000004A20719027B0B000004A207283B00000A0A2B00062A13300200170000000B000011001200FE15060000021200177D07000004060B2B00072A0013300200590000000500001100027B08000004283C00000A2D44027B09000004283C00000A2D37027B0A000004283C00000A2D2A027B0B000004283C00000A2D1D7E06000004027B0A0000046F3D00000A6F3E00000A15FE0116FE012B0116000A2B00062A00000013300300A60000000C000011000F00281D00000A16FE010D092D0B28180000060C388A0000001200FE15060000020F00281E00000A72DB0200706F3F00000A6F4000000A0B078E691AFE010D092D0B72DF020070734100000A7A120007169A6F4200000A7D08000004120007179A6F4200000A7D09000004120007189A6F4200000A7D0A000004120007199A6F4200000A7D0B000004120028190000060D092D0B7280030070734100000A7A060C2B00082A000013300200340000000D000011000F012815000006022815000006284300000A16FE010B072D0C230000000000002E400A2B0C2300000000000039400A2B00062ACA0002036F2600000A7D0800000402036F2600000A7D0900000402036F2600000A7D0A00000402036F2600000A7D0B0000042ADA0003027B080000046F2900000A0003027B090000046F2900000A0003027B0A0000046F2900000A0003027B0B0000046F2900000A002A0000133002007D0200000E000011734400000A0A0672170400706F4500000A0006721D0400706F4500000A000672230400706F4500000A000672290400706F4500000A0006722F0400706F4500000A000672350400706F4500000A0006723B0400706F4500000A000672410400706F4500000A000672470400706F4500000A0006724D0400706F4500000A000672530400706F4500000A000672590400706F4500000A0006725F0400706F4500000A000672650400706F4500000A0006726B0400706F4500000A000672710400706F4500000A000672770400706F4500000A0006727D0400706F4500000A000672830400706F4500000A000672890400706F4500000A0006728F0400706F4500000A000672950400706F4500000A0006729B0400706F4500000A000672A10400706F4500000A000672A70400706F4500000A000672AD0400706F4500000A000672B30400706F4500000A000672B90400706F4500000A000672BF0400706F4500000A000672C50400706F4500000A000672CB0400706F4500000A000672D10400706F4500000A000672D70400706F4500000A000672DD0400706F4500000A000672E30400706F4500000A000672E90400706F4500000A000672EF0400706F4500000A000672F50400706F4500000A000672FB0400706F4500000A000672010500706F4500000A000672070500706F4500000A0006720D0500706F4500000A000672130500706F4500000A000672190500706F4500000A0006721F0500706F4500000A000672250500706F4500000A0006722B0500706F4500000A000672310500706F4500000A000672370500706F4500000A0006723D0500706F4500000A000672430500706F4500000A000672490500706F4500000A000680060000042A00000042534A4201000100000000000C00000076322E302E35303732370000000005006C00000010070000237E00007C0700008407000023537472696E677300000000000F0000500500002355530050140000100000002347554944000000601400003006000023426C6F6200000000000000020000015717A2090902000000FA253300160000010000002C000000060000000B0000001E0000001C0000000300000045000000110000000E0000000100000006000000060000000100000001000000020000000100000000000A00010000000000060074006D0006007B006D000A00AC0091000A00D200BD000A00DC00BD000A000F01BD000600590146010600A9019D010A00CF01BD000600FE01F40106001002F401060076025B0206009303740306000A04F7033B001E04000006004D042D0406006D042D040A00930491000A00BF04BD000600E8046D00060011057403060027057403060032056D000A00480591000A0069059100060077056D000A009A0591000A00C605B0050A00E705D4050A00F905B0050A000406B0050A002A06B0050A00370685000A004506D4050A005106850006007B066D000A008B06D4050600B606A5060600C3066D000A00D706B0050A00F306D4050A00000791000A001C079100060064076D00000000000100000000000100010001001000160000000500010001000B0110002B00000009000100070001201000370000000500050007000100100043000000050006000E000921100054000000090006001200060081013E00060088013E0006008F013E00060096013E000100B701410031007D02710001008A027800010090027B00010099027B0001009F027B000100A6027B005020000000009600E5000A0001008C20000000009600F3000A000200C820000000009600190111000300A02100000000910029011E000700002200000000960065012F000C00BB250000000086187B013A000F00C325000000008600CA013A000F00D425000000008600D90145000F000C26000000008600E4014B0010002426000000008600EA01510011007F2600000000E6010B0256001100932600000000E6011D025C001200A8260000000086187B013A001300B026000000009600230262001300A02700000000960036026200160094280000000096004F026D001900A7280000000086187B013A001900B02800000000E609AF027E001900C828000000008608BA0282001900E028000000008608C60282001900F828000000008608CF02820019001029000000008608D90282001900282900000000C600E502820019007029000000009608EE02860019009429000000008100F7027E001900FC2900000000960007038B001900B02A0000000086000D0392001A00F02A00000000E6010B0256001B00232B00000000E6011D025C001C005C2B0000000091187B076D001D00000001004A03000001004A03000001004D03000002005503000003005D03000004006303000001006903020002006D0302000300A00302000400A70302000500AE0300000100B50300000200B90300000300BD0300000100C60300000100CC0300000100D20300000100D40300000100D60300000200DC0302000300E20300000100D60300000200DC0302000300E20300000100E90300000100EB0300000100D20300000100D40304000D000600110006000D0069007B013A0071007B01A50081007B01AB0089007B013A0091007B013A002900A80461012900B40467012900CA0470019900D604790129007B01AB003100DE043502A100ED043902A100F1043E02A100F5043902A100F9043902A100FE04390231007B0144023100AF027E002900AF027E002900DE048203A10003053E02A10009053E02A1000D053E0209007B013A00A9007B01A403B9007B013A00C1007B01AA0341007B013A004900AF027E004900DE048200410070051204410070051804410070052204D1007E057B004100840582034100E502280449007B012E0451008F05820041007B012E040900E502820059001D022E04D9007B013A00E1007B012E04E900F4053A00F1007B013F04F1001B064604F90041064B04110164065504F90072065C041101810663042901950682031101DE0468043101BD066C043901CF063A00F100E5067B0449010B027E0051017B01AA0359017B013A00D1006905F804D1002F070C05D1003D0782000C0045071705D10052071D05D1005E07220561017B012E04D10076078200D100CA04E5050C007B013A000C004106F00520002B00B0002E001B0007062E001300FE052E002300100640002B00B00060002B0084018300DB00B003A0002B005702C300CB018D04C00153013A04E00153013A04000253013A046002D301CF048002D301CF04A002D301CF04C002D301CF046003D30133057F014902520286031E04330471048104F404FF0405052905EB05F6050600010000002303980000002A039C00000032039C00000037039C0000003D039C0000004503A000020012000300020013000500020014000700020015000900020016000B00020018000D0011050480000000000000000000000000000000008B040000020000000000000000000000010064000000000002000000000000000000000001008500000000000300020000000000003C4D6F64756C653E00434C52546573742E646C6C0055736572446566696E656446756E6374696F6E7300426F756E64696E67426F7800436F6E636174656E6174650053746F72656450726F63656475726573005553506F7374616C41646472657373006D73636F726C69620053797374656D004F626A6563740056616C7565547970650053797374656D2E44617461004D6963726F736F66742E53716C5365727665722E536572766572004942696E61727953657269616C697A650053797374656D2E446174612E53716C547970657300494E756C6C61626C650053716C496E743332004576656E4E756D626572434C52004576656E4E756D626572434C5257697468446174614163636573730053716C446F75626C650043616C6344697374616E6365434C5200436972636C65426F756E64696E67426F785F46696C6C56616C7565730053797374656D2E436F6C6C656374696F6E730049456E756D657261626C650043616C63436972636C65426F756E64696E67426F78002E63746F72006D696E4C6174006D61784C6174006D696E4C6F6E006D61784C6F6E0053797374656D2E5465787400537472696E674275696C64657200696E7465726D656469617465526573756C7400496E69740053716C537472696E6700416363756D756C617465004D65726765005465726D696E6174650053797374656D2E494F0042696E61727952656164657200526561640042696E617279577269746572005772697465004578697374496E496E74657276616C434C52004578697374496E496E74657276616C526561646572434C5200456E646C6573734C6F6F700053797374656D2E436F6C6C656374696F6E732E47656E65726963004C6973746031005F76616C6964537461746573005F6E756C6C005F61646472657373005F63697479005F7374617465005F7A6970436F6465006765745F49734E756C6C006765745F41646472657373006765745F43697479006765745F5374617465006765745F5A6970436F646500546F537472696E67006765745F4E756C6C0056616C6964617465416464726573730050617273650043616C63756C6174655368697070696E67436F73740049734E756C6C00416464726573730043697479005374617465005A6970436F6465004E756C6C0069640066726F6D4C61740066726F6D4C6F6E00746F4C617400746F4C6F6E006F626A004D696E4C61740053797374656D2E52756E74696D652E496E7465726F705365727669636573004F7574417474726962757465004D61784C6174004D696E4C6F6E004D61784C6F6E006C6174006C6F6E0064697374616E63650076616C7565006F7468657200720077006D696E4964006D6178496400726F77436E7400730064657374696E6174696F6E0053797374656D2E446961676E6F73746963730044656275676761626C6541747472696275746500446562756767696E674D6F6465730053797374656D2E52756E74696D652E436F6D70696C6572536572766963657300436F6D70696C6174696F6E52656C61786174696F6E734174747269627574650052756E74696D65436F6D7061746962696C69747941747472696275746500434C52546573740053716C46756E6374696F6E417474726962757465006F705F496D706C69636974006F705F4D6F64756C75730053716C426F6F6C65616E006F705F457175616C697479006F705F54727565006765745F56616C7565004D6174680053696E00506F7700436F730053717274004173696E004174616E32004D696E004D6178005374727563744C61796F7574417474726962757465004C61796F75744B696E640053657269616C697A61626C654174747269627574650053716C55736572446566696E656441676772656761746541747472696275746500466F726D617400417070656E6400537472696E6700456D707479006765745F4C656E6774680052656164537472696E670053716C50726F6365647572654174747269627574650053797374656D2E446174612E53716C436C69656E740053716C436F6E6E656374696F6E0053797374656D2E446174612E436F6D6D6F6E004462436F6E6E656374696F6E004F70656E0053716C436F6D6D616E640053716C506172616D65746572436F6C6C656374696F6E006765745F506172616D65746572730053716C506172616D657465720053716C44625479706500416464004462506172616D6574657200506172616D65746572446972656374696F6E007365745F446972656374696F6E006765745F4974656D00496E743332007365745F56616C7565004462436F6D6D616E6400457865637574654E6F6E51756572790053797374656D2E546872656164696E670054687265616400536C6565700049446973706F7361626C6500446973706F73650053716C446174615265616465720045786563757465526561646572004462446174615265616465720053716C55736572446566696E6564547970654174747269627574650053716C4D6574686F644174747269627574650049734E756C6C4F72456D70747900546F55707065720042696E61727953656172636800546F4368617241727261790053706C697400417267756D656E74457863657074696F6E005472696D002E6363746F72000000002F63006F006E007400650078007400200063006F006E006E0065006300740069006F006E003D00740072007500650000818D730065006C006500630074002000400052006500730075006C00740020003D0020000D000A002000200020002000200020002000200020002000200020002000200020002000630061007300650020000D000A00200020002000200020002000200020002000200020002000200020002000200020002000200020007700680065006E0020006500780069007300740073002800730065006C0065006300740020002A002000660072006F006D002000640062006F002E004E0075006D00620065007200730020007700680065007200650020004E0075006D003D0040004E0075006D00620065007200290020000D000A00200020002000200020002000200020002000200020002000200020002000200020002000200020007400680065006E002000310020000D000A002000200020002000200020002000200020002000200020002000200020002000200020002000200065006C00730065002000300020000D000A00200020002000200020002000200020002000200020002000200020002000200065006E006400000F400052006500730075006C007400000F40004E0075006D006200650072000080B7730065006C0065006300740020004E0075006D0020000D000A00200020002000200020002000200020002000200020002000660072006F006D002000640062006F002E004E0075006D00620065007200730020000D000A002000200020002000200020002000200020002000200020007700680065007200650020004E0075006D0020006200650074007700650065006E00200040004D0069006E0049006400200061006E006400200040004D006100780049006400000D40004D0069006E0049006400000D40004D00610078004900640000257B0030007D002C0020007B0031007D002C0020007B0032007D002C0020007B0033007D0000032C0000809F5400680065002000760061006C00750065002000680061007300200069006E0063006F0072007200650063007400200066006F0072006D00610074002E002000530068006F0075006C00640020006200650020003C0041006400640072006500730073003E002C0020003C0043006900740079003E002C0020003C00530074006100740065003E002C0020003C005A006900700043006F00640065003E000080955400680065002000760061006C00750065002000680061007300200069006E0063006F0072007200650063007400200066006F0072006D00610074002E00200041007400740072006900620075007400650073002000610072006500200065006D0070007400790020006F007200200053007400610074006500200069007300200069006E0063006F0072007200650063007400000541004B00000541004C00000541005200000541005A00000543004100000543004F00000543005400000544004300000544004500000546004C00000547004100000548004900000549004100000549004400000549004C00000549004E0000054B00530000054B00590000054C00410000054D00410000054D00440000054D00450000054D00490000054D004E0000054D004F0000054D00530000054D00540000054E00430000054E00440000054E00450000054E00480000054E004A0000054E004D0000054E00560000054E00590000054F00480000054F004B0000054F005200000550004100000550005200000552004900000553004300000553004400000554004E000005540058000005550054000005560041000005560054000005570041000005570049000005570056000005570059000000FE6044CCA6E89B4594DDB1E4A0AB1ED20008B77A5C561934E089060001111511150C000411191119111911191119100005011C1011191011191011191011190A0003121D1119111911150320000102060D03061221052001011125052001011210042000112505200101122905200101122D0A00030111151115101115030000010606151231010E02060202060E032000020320000E0400001118060001111811250520010D1118032800020328000E040800111805200101113D042001010880AF0100030054020F497344657465726D696E697374696301540209497350726563697365015455794D6963726F736F66742E53716C5365727665722E5365727665722E446174614163636573734B696E642C2053797374656D2E446174612C2056657273696F6E3D322E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D623737613563353631393334653038390A4461746141636365737301000000050001111508080002111511151115080002114D1115111505000102114D040701111580AF0100030054020F497344657465726D696E697374696301540209497350726563697365005455794D6963726F736F66742E53716C5365727665722E5365727665722E446174614163636573734B696E642C2053797374656D2E446174612C2056657273696F6E3D322E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D623737613563353631393334653038390A44617461416363657373000000000320000D0400010D0D0500020D0D0D042001010D0807050D0D0D0D1119040701110C8129010005005455794D6963726F736F66742E53716C5365727665722E5365727665722E446174614163636573734B696E642C2053797374656D2E446174612C2056657273696F6E3D322E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D623737613563353631393334653038390A446174614163636573730000000054020F497344657465726D696E69737469630154020949735072656369736500540E1146696C6C526F774D6574686F644E616D651C436972636C65426F756E64696E67426F785F46696C6C56616C756573540E0F5461626C65446566696E6974696F6E364D696E4C617420666C6F61742C204D61784C617420666C6F61742C204D696E4C6F6E20666C6F61742C204D61784C6F6E20666C6F6174032000081D07181D110C0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D121D020520010111590520010111656101000200000004005402124973496E76617269616E74546F4E756C6C73015402174973496E76617269616E74546F4475706C696361746573005402124973496E76617269616E74546F4F726465720054080B4D61784279746553697A65401F000005200112210E0520011221030307010205200112211C0520020E0808042001010E0607030E1125020401000000062002010E1271042000127D0920021280810E1180850620010111808D06200112808108042001011C0320001C0400010108090705081271127908020520001280A10B070508127112791280A102410100020000000200540E1456616C69646174696F6E4D6574686F644E616D650F56616C69646174654164647265737354080B4D61784279746553697A65401F0000240100020054020F497344657465726D696E697374696301540209497350726563697365010307010E0600020E0E1D1C0507020E1D1C06070211181118040001020E05151231010E0520010813000420001D030620011D0E1D0309070411181D0E11180280B00100030054020A4F6E4E756C6C43616C6C0054020F497344657465726D696E6973746963015455794D6963726F736F66742E53716C5365727665722E5365727665722E446174614163636573734B696E642C2053797374656D2E446174612C2056657273696F6E3D322E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D623737613563353631393334653038390A4461746141636365737300000000050002020E0E0407020D02052001011300070701151231010E0801000701000000000801000800000000001E01000100540216577261704E6F6E457863657074696F6E5468726F777301000000000017186D5300000000020000001C01000094480000942A000052534453E875CC2294F5B04AB34EDF456BFA8BB604000000633A5C576F726B5C434C52546573745C434C52546573745C6F626A5C44656275675C434C52546573742E7064620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000D84900000000000000000000EE490000002000000000000000000000000000000000000000000000E04900000000000000005F436F72446C6C4D61696E006D73636F7265652E646C6C0000000000FF25002000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058600000440200000000000000000000440234000000560053005F00560045005200530049004F004E005F0049004E0046004F0000000000BD04EFFE00000100000000000000000000000000000000003F000000000000000400000002000000000000000000000000000000440000000100560061007200460069006C00650049006E0066006F00000000002400040000005400720061006E0073006C006100740069006F006E00000000000000B004A4010000010053007400720069006E006700460069006C00650049006E0066006F0000008001000001003000300030003000300034006200300000002C0002000100460069006C0065004400650073006300720069007000740069006F006E000000000020000000300008000100460069006C006500560065007200730069006F006E000000000030002E0030002E0030002E003000000038000C00010049006E007400650072006E0061006C004E0061006D006500000043004C00520054006500730074002E0064006C006C0000002800020001004C006500670061006C0043006F00700079007200690067006800740000002000000040000C0001004F0072006900670069006E0061006C00460069006C0065006E0061006D006500000043004C00520054006500730074002E0064006C006C000000340008000100500072006F006400750063007400560065007200730069006F006E00000030002E0030002E0030002E003000000038000800010041007300730065006D0062006C0079002000560065007200730069006F006E00000030002E0030002E0030002E00300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000C000000003A00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
with permission_set = safe
go

create function [dbo].[EvenNumberCLR] (@id int)
returns int
as external name 
	[CLRTest].[UserDefinedFunctions].[EvenNumberCLR];
go

create function [dbo].[EvenNumberCLRWithDataAccess] (@id int)
returns int
as external name 
	[CLRTest].[UserDefinedFunctions].[EvenNumberCLRWithDataAccess];
go

create procedure [dbo].[ExistInIntervalCLR]
	@minId int,
	@maxId int,
	@rowCnt int output
as external name 
	[CLRTest].[StoredProcedures].[ExistInIntervalCLR]
go

create procedure [dbo].[ExistInIntervalReaderCLR]
	@minId int,
	@maxId int,
	@rowCnt int output
as external name 
	[CLRTest].[StoredProcedures].[ExistInIntervalReaderCLR]
go

create function [dbo].[CalcDistanceCLR]
(
	@fromLat float(53),
	@fromLon float(53),
	@toLat float(53),
	@toLon float(53)
)
returns float(53)
as external name 
	[CLRTest].[UserDefinedFunctions].[CalcDistanceCLR];
go

create function [dbo].[CalcCircleBoundingBox]
( 
	@lat float(53), 
	@lon float(53), 
	@distance int
)
returns table
(
	 [MinLat] float(53) null,
	 [MaxLat] float(53) null,
	 [MinLon] float(53) null,
	 [MaxLon] float(53) null
)
as external name 
	[CLRTest].[UserDefinedFunctions].[CalcCircleBoundingBox]
go

create procedure [dbo].[EndlessLoop]
as external name 
	[CLRTest].[StoredProcedures].[EndlessLoop]
go


create aggregate [dbo].[Concatenate](@value nvarchar (4000))
returns nvarchar (4000)
external name [CLRTest].[Concatenate]
go

create type [dbo].[USPostalAddress]
external name [CLRTest].[USPostalAddress]
go

create table dbo.Numbers
(
	Num int not null,
	
	constraint PK_Numbers
	primary key clustered(Num)
);
go

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2 cross join N2 AS T3) -- 262,144 rows
,Nums(Num) as (select row_number() over (order by (select null)) from N5)
insert into dbo.Numbers(Num) 
	select Num from Nums;
