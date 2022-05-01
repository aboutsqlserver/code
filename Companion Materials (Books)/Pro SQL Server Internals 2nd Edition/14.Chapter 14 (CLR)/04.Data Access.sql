/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 2nd Edition. ISBN-13: 978-1484219638 ISBN-10:1484219635     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                            Chapter 14. CLR                               */
/*                        Data Access Performance                           */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*   That script uses objects created by "01.Object Creation.sql" script    */
/****************************************************************************/

if exists(select * from sys.procedures p join sys.schemas s on p.schema_id = s.schema_id where s.name = 'dbo' and p.name = 'ExistInInterval') drop proc dbo.ExistInInterval;
go

/*** CLR CODE ***/
/*
[Microsoft.SqlServer.Server.SqlProcedure]
public static void ExistInIntervalCLR
(
	SqlInt32 minNum, 
	SqlInt32 maxNum, 
	out SqlInt32 rowCnt
)
{
	int result = 0;
	using (SqlConnection conn = new SqlConnection("context connection=true"))
	{
		conn.Open();
		SqlCommand cmd = new SqlCommand(
@"select Num 
from dbo.Numbers 
where Num between @minNum and @maxNum", conn);

		cmd.Parameters.Add("@Result", SqlDbType.Int).Direction = ParameterDirection.Output;
		cmd.Parameters.Add("@Number", SqlDbType.Int);
		for (int i = minNum.Value; i <= maxNum.Value; i++)
		{
			cmd.Parameters[1].Value = i;
			cmd.ExecuteNonQuery();
			result += (int)cmd.Parameters[0].Value;
			System.Threading.Thread.Sleep(0);
		}
	}
	rowCnt = new SqlInt32(result);
}
*/

create proc dbo.ExistInInterval 
(
	@MinNum int
	,@MaxNum int
	,@RowCount int output
)
as
	set nocount on
	
	set @RowCount = 0;
	while @MinNum <= @MaxNum    
	begin
		if exists
		(
			select * 
			from dbo.Numbers 
			where Num = @MinNum
		)
			set @RowCount = @RowCount + 1;
		set @MinNum = @MinNum + 1;
	end
go


declare	
	@rowCnt int
	,@dt datetime 
	
select @dt = getdate();
exec dbo.ExistInInterval 0, 200000, @RowCnt output;
select @RowCnt,datediff(millisecond,@dt,getdate()) as [T-SQL Execution Time];

select @dt = getdate();
exec dbo.ExistInIntervalClr 0, 200000, @RowCnt output;
select @RowCnt,datediff(millisecond,@dt,getdate()) as [CLR Execution Time];
go 