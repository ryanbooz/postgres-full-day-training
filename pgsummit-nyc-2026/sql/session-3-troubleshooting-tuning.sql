-- ============================================================
-- SQL examples from: session-3-troubleshooting-tuning
-- ============================================================
-- ------------------------------------------
-- Slide 6: 🔧 Demo: Create a Blocking Lock
-- ------------------------------------------

BEGIN;
UPDATE bluebox.film
SET popularity = popularity
WHERE film_id = 155;
-- no COMMIT yet: this session is
-- now "idle in transaction"

UPDATE bluebox.film
SET popularity = popularity
WHERE film_id = 155;
-- hangs: waiting for window 1's
-- row lock


-- ---------------------------------
-- Slide 7: Who Is Blocking Whom?
-- ---------------------------------

SELECT pid,
       pg_blocking_pids(pid) AS blocked_by,
       wait_event_type,
       NOW() - query_start AS waiting,
       LEFT(query, 40) AS query
FROM pg_stat_activity
WHERE cardinality(pg_blocking_pids(pid)) > 0;


-- ----------------------------------------
-- Slide 8: Finding Long-Running Queries
-- ----------------------------------------

SELECT 
    pid,
    NOW() - query_start as duration,
    usename,
    state,
    query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start
LIMIT 10;


-- -------------------------------------
-- Slide 9: Finding Idle Transactions
-- -------------------------------------

-- Idle transactions can hold locks!
SELECT 
    pid,
    NOW() - xact_start as transaction_duration,
    NOW() - state_change as idle_duration,
    usename,
    query
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND xact_start IS NOT NULL
ORDER BY xact_start;


-- ------------------------------
-- Slide 10: Canceling a Query
-- ------------------------------

-- Cancel the current query (graceful)
SELECT pg_cancel_backend(12345);

-- Returns true if signal sent successfully


-- -------------------------------------
-- Slide 11: Terminating a Connection
-- -------------------------------------

-- Terminate the entire connection (forceful)
SELECT pg_terminate_backend(12345);

-- Terminate all connections to a database except our own
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'bluebox'
  AND pid != pg_backend_pid();


-- ------------------------------
-- Slide 12: Statement Timeout
-- ------------------------------

-- Set for session
SET statement_timeout = '30s';

-- Set for a single transaction
BEGIN;
SET LOCAL statement_timeout = '10s';
SELECT * FROM huge_table;  -- Will timeout after 10s
COMMIT;

-- Set per user
ALTER ROLE app_user SET statement_timeout = '60s';


-- -------------------------------------
-- Slide 13: Idle Transaction Timeout
-- -------------------------------------

-- postgresql.conf or per-session
idle_in_transaction_session_timeout = '10min'

-- Per user
ALTER ROLE app_user SET idle_in_transaction_session_timeout = '5min';


-- -------------------------
-- Slide 14: Lock Timeout
-- -------------------------

-- Set lock timeout
SET lock_timeout = '5s';

-- Now this will fail fast if table is locked
ALTER TABLE bluebox.rental ADD COLUMN new_col INT;

-- ERROR: canceling statement due to lock timeout


-- ---------------------------------
-- Slide 17: Key Metrics to Watch
-- ---------------------------------

-- Connection count
SELECT count(*) FROM pg_stat_activity;

-- Database size growth
SELECT pg_database_size('bluebox');

-- Transaction rate (per second)
SELECT (xact_commit + xact_rollback) / extract(epoch from now() -  coalesce(stats_reset, 
(pg_catalog.pg_stat_file('base/' || datid || '/PG_VERSION')).modification)) AS tps
FROM pg_stat_database 
WHERE datname = 'bluebox';


-- ----------------------------
-- Slide 18: Cache Hit Ratio
-- ----------------------------

SELECT 
    datname,
    ROUND(
        blks_hit::numeric / NULLIF(blks_hit + blks_read, 0) * 100, 
        2
    ) as cache_hit_ratio
FROM pg_stat_database
WHERE datname = 'bluebox';

-- Should be > 99% for OLTP workloads


-- --------------------------------------
-- Slide 20: Simple Health Check Query
-- --------------------------------------

SELECT 
    'connections' as metric, 
    count(*)::text as value 
FROM pg_stat_activity
UNION ALL
SELECT 
    'database_size', 
    pg_size_pretty(pg_database_size('bluebox'))
UNION ALL
SELECT 
    'active_queries', 
    count(*)::text 
FROM pg_stat_activity 
WHERE state = 'active'
UNION ALL
SELECT 
    'oldest_transaction', 
    COALESCE(max(NOW() - xact_start)::text, 'none')
FROM pg_stat_activity;


-- -------------------------------------------------------
-- Slide 21: `pg_stat_statements`: Finding Slow Queries
-- -------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT 
    LEFT(query, 60) as query,
    calls,
    ROUND(total_exec_time::numeric, 2) as total_ms,
    ROUND(mean_exec_time::numeric, 2) as avg_ms,
    ROUND((100 * total_exec_time / 
        SUM(total_exec_time) OVER ())::numeric, 2) as pct
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;


-- ---------------------------
-- Slide 23: Shared Buffers
-- ---------------------------

-- Check current value
SHOW shared_buffers;

-- Set in postgresql.conf
shared_buffers = 8GB   -- For 32GB RAM system

-- Requires restart to change


-- ------------------------------
-- Slide 25: What is work_mem?
-- ------------------------------

SHOW work_mem;  -- Default: 4MB


-- -----------------------------
-- Slide 26: Setting work_mem
-- -----------------------------

-- Global setting (conservative)
work_mem = 64MB

-- Increase for specific session
SET work_mem = '256MB';
-- Run complex analytical query
RESET work_mem;


-- ------------------------------------
-- Slide 27: Maintenance Work Memory
-- ------------------------------------

maintenance_work_mem = 1GB

-- Affects:
-- VACUUM
-- CREATE INDEX
-- ALTER TABLE ADD FOREIGN KEY


-- --------------------------------------
-- Slide 28: When to Increase work_mem
-- --------------------------------------

-- Check for disk sorts
EXPLAIN (ANALYZE, BUFFERS) SELECT ...

-- Look for:
-- Sort Method: external merge  ← disk sort, increase work_mem
-- Sort Method: quicksort      ← memory sort, good!


-- -----------------------------
-- Slide 30: What is EXPLAIN?
-- -----------------------------

EXPLAIN SELECT * FROM bluebox.film WHERE vote_average > 8;


-- ----------------------------
-- Slide 31: EXPLAIN Options
-- ----------------------------

-- Basic plan (estimated only)
EXPLAIN SELECT * FROM bluebox.film WHERE vote_average > 8;

-- With actual execution times
EXPLAIN ANALYZE SELECT * FROM bluebox.film WHERE vote_average > 8;

-- With buffer/IO statistics
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM bluebox.film WHERE vote_average > 8;

-- All the details in text format
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT * FROM bluebox.film WHERE vote_average > 8;


-- ----------------------------
-- Slide 33: EXPLAIN ANALYZE
-- ----------------------------

EXPLAIN ANALYZE 
SELECT * FROM bluebox.film WHERE vote_average > 8;


-- ------------------------------------------
-- Slide 34: Warning About EXPLAIN ANALYZE
-- ------------------------------------------

-- This will DELETE your data!
EXPLAIN ANALYZE DELETE FROM bluebox.customer;

-- Use ROLLBACK for data-modifying queries
BEGIN;
EXPLAIN ANALYZE DELETE FROM bluebox.customer;
ROLLBACK;


-- ---------------------------------
-- Slide 35: EXPLAIN with BUFFERS
-- ---------------------------------

EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM bluebox.film WHERE vote_average > 8;


-- ------------------------------------------
-- Slide 41: Join Operations - Nested Loop
-- ------------------------------------------

EXPLAIN SELECT f.title, p.name FROM bluebox.film f
JOIN bluebox.film_cast fc ON f.film_id = fc.film_id
JOIN bluebox.person p ON fc.person_id = p.person_id
WHERE f.film_id = 155;


-- -----------------------------------
-- Slide 45: B-Tree Index (Default)
-- -----------------------------------

-- BEFORE: Check the plan without an index
EXPLAIN ANALYZE 
SELECT title FROM bluebox.film WHERE vote_average > 8;
-- Seq Scan on film  (cost=0.00..941.95)
--   Filter: (vote_average > 8)


-- --------------------------------
-- Slide 46: B-Tree Index: After
-- --------------------------------

-- Create the index
CREATE INDEX idx_film_vote_avg ON bluebox.film(vote_average);

-- AFTER: Check the plan with the index
EXPLAIN ANALYZE 
SELECT title FROM bluebox.film WHERE vote_average > 8;
-- Bitmap Heap Scan on film  (cost=5.13..308.25 rows=110)
--   Recheck Cond: (vote_average > 8)
--   ->  Bitmap Index Scan on idx_film_vote_avg  (cost=0.00..5.11 rows=110)
--         Index Cond: (vote_average > 8)


-- ---------------------------------
-- Slide 50: Pattern: N+1 Queries
-- ---------------------------------

-- GOOD: Single query
SELECT c.*, r.* 
FROM customer c 
LEFT JOIN rental r ON c.customer_id = r.customer_id;


-- ------------------------------
-- Slide 51: Pattern: SELECT *
-- ------------------------------

-- BAD: Gets all columns
SELECT * FROM bluebox.film WHERE vote_average > 8;

-- GOOD: Only needed columns
SELECT film_id, title, vote_average 
FROM bluebox.film 
WHERE vote_average > 8;


-- -------------------------------------------
-- Slide 52: Pattern: OFFSET for Pagination
-- -------------------------------------------

-- BAD: Must scan 10000 rows to skip them
SELECT * FROM bluebox.rental 
ORDER BY rental_id 
OFFSET 10000 LIMIT 20;

-- GOOD: Use index
SELECT * FROM bluebox.rental 
WHERE rental_id > 10000 
ORDER BY rental_id 
LIMIT 20;


-- --------------------------------------------------
-- Slide 53: Pattern: Functions on Indexed Columns
-- --------------------------------------------------

-- BAD: Can't use index efficiently  
SELECT * FROM bluebox.payment 
WHERE DATE(payment_date) = '2024-01-15';

-- GOOD: Can use index
SELECT * FROM bluebox.payment 
WHERE payment_date >= '2024-01-15' 
  AND payment_date < '2024-01-16';
