-- ============================================================
-- SQL examples from: session-2-dba-basics
-- ============================================================
-- ----------------------------
-- Slide 6: 🔧 Demo: View WAL
-- ----------------------------

-- Current WAL position (Log Sequence Number)
SELECT pg_current_wal_lsn();
--  0/3A8B9D0

-- WAL stats
SELECT wal_records, wal_bytes, 
       pg_size_pretty(wal_bytes) as wal_size
FROM pg_stat_wal;


-- ---------------------------------------------
-- Slide 44: 🔧 Demo: Finding Idle Connections
-- ---------------------------------------------

SELECT pid, usename, state, query_start, state_change
FROM pg_stat_activity 
WHERE state = 'idle'
ORDER BY state_change;


-- ----------------------------
-- Slide 48: What is Vacuum?
-- ----------------------------

-- Manual vacuum
VACUUM bluebox.rental;

-- Vacuum with analysis
VACUUM ANALYZE bluebox.rental;

-- Full vacuum (rewrites table, locks!)
VACUUM FULL bluebox.rental;


-- -----------------------
-- Slide 49: Autovacuum
-- -----------------------

-- Key settings
autovacuum = on
autovacuum_vacuum_threshold = 50
autovacuum_vacuum_scale_factor = 0.2

-- 20% of rows changed + 50 = trigger vacuum


-- -----------------------------------
-- Slide 50: Monitoring Table Bloat
-- -----------------------------------

-- Check dead tuples
SELECT 
    schemaname,
    relname,
    n_dead_tup,
    n_live_tup,
    round(n_dead_tup::numeric / NULLIF(n_live_tup, 0) * 100, 2) as dead_pct
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC
LIMIT 10;


-- ----------------------------------
-- Slide 51: Table and Index Bloat
-- ----------------------------------

-- pgstattuple is a contrib extension (more on extensions at the end of this session)
CREATE EXTENSION pgstattuple;

SELECT * FROM pgstattuple('bluebox.rental');


-- ----------------------------------
-- Slide 52: Disk Space Monitoring
-- ----------------------------------

SELECT pg_size_pretty(pg_database_size('bluebox'));
-- Result: 876 MB

SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) as size
FROM pg_stat_user_tables WHERE schemaname = 'bluebox'
ORDER BY pg_total_relation_size(relid) DESC LIMIT 5;
