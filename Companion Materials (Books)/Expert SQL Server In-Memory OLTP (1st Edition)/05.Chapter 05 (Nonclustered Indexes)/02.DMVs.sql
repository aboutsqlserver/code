/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 1st Edition. ISBN-13:978-1484211373  ISBN-10:1484211375     */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                    Chapter 05: Nonclustered Indexes                      */
/*           02.Obtaining Information about Nonclustered Indexes            */
/****************************************************************************/

set nocount on
go

use InMemoryOLTP2014
go

select 
	s.name + '.' + t.name as [table]
	,i.index_id    
	,i.name as [index]
	,i.type_desc as [type]
	,st.scans_started
	,st.rows_returned
	,iif(st.scans_started = 0, 0, 
		floor(st.rows_returned / st.scans_started)) as [rows per scan]
from 
	sys.dm_db_xtp_index_stats st join sys.tables t on
		st.object_id = t.object_id
	join sys.indexes i on
		st.object_id = i.object_id and 
		st.index_id = i.index_id
	join sys.schemas s on
		s.schema_id = t.schema_id
where
	s.name = 'dbo' and t.name = 'Customers';

select 
	s.name + '.' + t.name as [table]
	,i.index_id    
	,i.name as [index]
	,i.type_desc as [type]
	,st.delta_pages
	,st.leaf_pages
	,st.internal_pages
	,st.leaf_pages + st.delta_pages + st.internal_pages 
		as [total pages]
from 
	sys.dm_db_xtp_nonclustered_index_stats st 
		join sys.tables t on
			st.object_id = t.object_id
		join sys.indexes i on
			st.object_id = i.object_id and 
			st.index_id = i.index_id
		join sys.schemas s on
			s.schema_id = t.schema_id
where
	s.name = 'dbo' and t.name = 'Customers';

