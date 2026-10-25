-- Clip D4.2, SQL Server side: what a maintenance plan reads before REORGANIZE or REBUILD.
-- SQL Server 2022, base PachaDataFormation, sqlcmd. Read only; SAMPLED mode reads a sample
-- of the leaf pages and gives the page density as well as the fragmentation.
set nocount on;
select top (8) object_schema_name(ps.object_id) + '.' + object_name(ps.object_id) as table_name,
       i.name as index_name, ps.index_type_desc, ps.page_count,
       cast(ps.avg_fragmentation_in_percent as decimal(5, 1)) as fragmentation_pct,
       cast(ps.avg_page_space_used_in_percent as decimal(5, 1)) as page_density_pct
from sys.dm_db_index_physical_stats(db_id(), null, null, null, 'SAMPLED') as ps
join sys.indexes as i on i.object_id = ps.object_id and i.index_id = ps.index_id
where ps.page_count > 500 and ps.alloc_unit_type_desc = 'IN_ROW_DATA'
order by ps.page_count desc;
