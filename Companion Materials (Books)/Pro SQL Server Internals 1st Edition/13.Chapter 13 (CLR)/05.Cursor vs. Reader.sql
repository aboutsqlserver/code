/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                            Chapter 13. CLR                               */
/*                           Cursor vs. Reader                              */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*   That script uses objects created by "01.Object Creation.sql" script    */
/****************************************************************************/

if exists(
	select * 
	from sys.procedures p join sys.schemas s on 
		p.schema_id = s.schema_id
	where 
		p.name = 'ExistInIntervalCursor' and s.name = 'dbo' 
)
	drop proc dbo.ExistInIntervalCursor 
go

/*** CLR CODE ***/
/*
[Microsoft.SqlServer.Server.SqlProcedure]
public static void ExistInIntervalReaderCLR
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
where Num between @MinNum and @MaxNum", conn);

		cmd.Parameters.Add("@MinNum", SqlDbType.Int).Value = minNum;
		cmd.Parameters.Add("@MaxNum", SqlDbType.Int).Value = maxNum;
		using (SqlDataReader reader = cmd.ExecuteReader())
		{
			while (reader.Read())
			{
				result++;
				-- Yielding every 500 rows
				if (result % 500 == 0) 
					System.Threading.Thread.Sleep(0);
			}
		}         
	}
	rowCnt = new SqlInt32(result);
}
*/

create proc dbo.ExistInIntervalCursor
(
	@MinNum int
	,@MaxNum int
	,@RowCount int output
)
as 
	set nocount on
	declare 
		@Num int  

	declare 
		curWork cursor fast_forward
		for
			select Num
			from dbo.Numbers
			where Num between @MinNum and @MaxNum

	set @RowCount = 0
   
	open curWork
	fetch next from curWork into @Num	
	while @@fetch_status = 0 
	begin
		set @RowCount = @RowCount + 1
		fetch next from curWork into @Num	
	end  
	close curWork
	deallocate curWork
go

declare	
	@rowCnt int
	,@dt datetime 
	
select @dt = getdate()
exec dbo.ExistInIntervalCursor 0, 200000, @RowCnt output
select @RowCnt,datediff(millisecond,@dt,getdate()) as [T-SQL Execution Time]

select @dt = getdate()
exec dbo.ExistInIntervalReaderClr 0, 200000, @RowCnt output
select @RowCnt,datediff(millisecond,@dt,getdate()) as [CLR Execution Time]
go 
