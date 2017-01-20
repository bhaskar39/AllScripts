SELECT ps.database_id, ps.OBJECT_ID, ps.index_id, si.name, ps.avg_fragmentation_in_percent,
(SELECT distinct so.name FROM sys.objects so INNER JOIN sys.indexes ON so.object_id = si.object_id) ParentTable
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS ps
INNER JOIN sys.indexes si ON ps.OBJECT_ID = si.OBJECT_ID
AND ps.index_id = si.index_id
WHERE ps.database_id = DB_ID() AND si.name is not null AND
ps.avg_fragmentation_in_percent>5 
ORDER BY ps.avg_fragmentation_in_percent desc