/****************************************************************************/
/*                       Pro SQL Server Internals                           */
/*      APress. 1st Edition. ISBN-13: 978-1430259626 ISBN-10:1430259620     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                      dmitri@aboutsqlserver.com                           */
/****************************************************************************/
/*                            Chapter 13. CLR                               */
/*                               Aggregates                                 */
/****************************************************************************/

set nocount on
go

use [SqlServerInternals]
go

/****************************************************************************/
/*   That script uses objects created by "01.Object Creation.sql" script    */
/****************************************************************************/

/*** CLR CODE ***/
/*
[Serializable]
[SqlUserDefinedAggregate(
	Format.UserDefined, 
	IsInvariantToNulls=true, 
	IsInvariantToDuplicates=false,
	IsInvariantToOrder=false,
	MaxByteSize=-1
)]
public class Concatenate : IBinarySerialize
{
	// The buffer for the intermediate results
	private StringBuilder intermediateResult;

	// Initializes the buffer
	public void Init()
	{
		this.intermediateResult = new StringBuilder();
	}

	// Accumulate the next value if not null
	public void Accumulate(SqlString value)
	{
		if (value.IsNull)
			return;
		this.intermediateResult.Append(value.Value).Append(',');
	}

	// Merges the partiually completed aggregates
	public void Merge(Concatenate other)
	{
		this.intermediateResult.Append(other.intermediateResult);
	}

	// Called at the end of aggregation
	public SqlString Terminate()
	{
		string output = string.Empty;
		if (this.intermediateResult != null && this.intermediateResult.Length > 0)
		{ // Deleting the trailing comma
			output = this.intermediateResult.ToString(0, this.intermediateResult.Length - 1);
		}
		return new SqlString(output);
	}

	// Deserializing data
	public void Read(BinaryReader r)
	{
		intermediateResult = new StringBuilder(r.ReadString());
	}

	// Serializing data
	public void Write(BinaryWriter w)
	{
		w.Write(this.intermediateResult.ToString());
	}
}
*/



set statistics time on
go


/* SQL Server 2005 CLR Aggregates are limited to 8,000 bytes. It limits @MaxNum value */
declare	
	@MaxNum int 

select @MaxNum = 5000

/*** CLR Aggregate ***/
select dbo.Concatenate(convert(nvarchar(32), Num))
from dbo.Numbers
where Num <= @MaxNum


/*** SQL Variable ***/
declare	
	@V nvarchar(max) 

select @V = N''

select @V = @V + convert(nvarchar(32), Num) + ','
from dbo.Numbers
where Num <= @MaxNum
-- removing trailing comma
select @V = case when @V = '' then '' else left(@V,len(@V) - 1) end



/*** FOR XML PATH ***/
select case when Result is null then '' else left(Result,len(Result) - 1) end
from
	 (
		select 
			convert(nvarchar(max), 
	 			(
					select Num as [text()], ',' as [text()]
					from dbo.Numbers
					where Num <= @MaxNum
					for xml path('')
				)
			) as Result
	) r
set statistics time off
go
