autoscale: true
theme: Simple
background-color: #0B1C33
text: #F4EFE6, Helvetica Neue
header: #F0923C, Helvetica Neue Bold
header-strong: #F0923C, Helvetica Neue Bold
text-strong: #F0923C, Helvetica Neue Bold
text-emphasis: #7FB3E0, Helvetica Neue Italic
list: #F4EFE6, bullet-color(#F0923C)
code: auto(1), Menlo
inline-code: Menlo
table-separator: #F0923C, stroke-width(2)
link: #7FB3E0, Helvetica Neue
footer-style: #7E93B0, Helvetica Neue, text-scale(0.5)
quote: #F4EFE6, Helvetica Neue Italic
quote-author: #7FB3E0, Helvetica Neue

[.footer: Slide 1 / 63]

## When Postgres Misbehaves
### Locks, Monitoring & the Config That Matters
<br>
<br>
## Session 3 of 3 — Beginning Postgres Workshop
### PGSummit NYC 2026

^ WIP session assembled from hour-4-troubleshooting.md (locks + monitoring only), hour-5-performance.md (a few key memory settings only), and hour-6-query-tuning.md (EXPLAIN, index basics, common patterns) for PGSummit NYC. This is now the largest of the three sessions - per updated guidance, it leans much more on hour-6's EXPLAIN/index content than on hour-5's deep memory tuning, since a diagnostic mental model matters more to this audience than tuning depth. Talking/demo-led, not hands-on. See pgsummit-nyc-2026/README.md.

---

[.footer: Slide 2 / 63]

## Session 3 Topics

- Locks & blocking
- Finding and stopping bad queries, timeouts as guardrails
- Monitoring essentials
- A few key config settings (shared_buffers, work_mem)
- Reading query plans with EXPLAIN
- Index basics and common performance patterns

---

[.footer: Slide 3 / 63]

## Locks & Blocking

---

[.footer: Slide 4 / 63]

## pg_locks - Lock Information

```sql
SELECT 
    l.pid,
    l.locktype,
    l.mode,
    l.granted,
    a.usename,
    a.query
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE NOT l.granted;  -- Waiting locks
```

---

[.footer: Slide 5 / 63]

![fit](../diagrams/lock-types.png)

---

[.footer: Slide 6 / 63]

## Find the Source of a Lock

```sql
WITH sos AS (
  SELECT array_cat(array_agg(pid),
    array_agg((pg_blocking_pids(pid))[array_length(pg_blocking_pids(pid),1)])) pids
  FROM pg_locks WHERE NOT granted
)
SELECT a.pid, a.usename, a.state,
   a.wait_event_type || ': ' || a.wait_event AS wait_event,
   current_timestamp-a.state_change time_in_state,
   l.relation::regclass relname, l.locktype, l.mode,
   pg_blocking_pids(l.pid) blocking_pids,
   (pg_blocking_pids(l.pid))[array_length(pg_blocking_pids(l.pid),1)] last_session,
   coalesce((pg_blocking_pids(l.pid))[1]||'.'||coalesce(
     case when locktype='transactionid' then 1 
     else array_length(pg_blocking_pids(l.pid),1)+1 end,0),
     a.pid||'.0') lock_depth,
   a.query
FROM pg_stat_activity a
JOIN sos s ON (a.pid = any(s.pids))
LEFT OUTER JOIN pg_locks l ON (a.pid = l.pid and not l.granted)
ORDER BY lock_depth;
```

^ Passing mention: if you want to see lock waits show up in the Postgres log automatically, `log_lock_waits` will do that - detailed logging configuration is out of scope for this session.

---

[.footer: Slide 7 / 63]

## Finding and Killing Problems

---

[.footer: Slide 8 / 63]

## Common Problems

- Long-running queries blocking others
- Idle transactions holding locks
- Runaway queries consuming resources
- Connection exhaustion
- Lock contention

---

[.footer: Slide 9 / 63]

## Finding Long-Running Queries

```sql
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
```

---

[.footer: Slide 10 / 63]

## Finding Idle Transactions

```sql
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
```

---

[.footer: Slide 11 / 63]

## Finding Blocked Queries

```sql
SELECT 
    blocked.pid AS blocked_pid,
    blocked.query AS blocked_query,
    blocking.pid AS blocking_pid,
    blocking.query AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_locks blocked_locks ON blocked.pid = blocked_locks.pid
JOIN pg_locks blocking_locks ON blocked_locks.locktype = blocking_locks.locktype
    AND blocked_locks.relation = blocking_locks.relation
    AND blocked_locks.pid != blocking_locks.pid
JOIN pg_stat_activity blocking ON blocking_locks.pid = blocking.pid
WHERE NOT blocked_locks.granted;
```

---

[.footer: Slide 12 / 63]

## Canceling a Query

```sql
-- Cancel the current query (graceful)
SELECT pg_cancel_backend(12345);

-- Returns true if signal sent successfully
```

The query receives an interrupt and can clean up

---

[.footer: Slide 13 / 63]

## Terminating a Connection

```sql
-- Terminate the entire connection (forceful)
SELECT pg_terminate_backend(12345);

-- Terminate all connections to a database except our own
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'bluebox'
  AND pid != pg_backend_pid();
```

---

[.footer: Slide 14 / 63]

## Statement Timeout

Automatically kill queries that run too long

```sql
-- Set for session
SET statement_timeout = '30s';

-- Set for a single transaction
BEGIN;
SET LOCAL statement_timeout = '10s';
SELECT * FROM huge_table;  -- Will timeout after 10s
COMMIT;

-- Set per user
ALTER ROLE app_user SET statement_timeout = '60s';
```

---

[.footer: Slide 15 / 63]

## Idle Transaction Timeout

Kill sessions that sit idle in a transaction

```sql
-- postgresql.conf or per-session
idle_in_transaction_session_timeout = '10min'

-- Per user
ALTER ROLE app_user SET idle_in_transaction_session_timeout = '5min';
```

---

[.footer: Slide 16 / 63]

## Lock Timeout

Don't wait forever for locks

```sql
-- Set lock timeout
SET lock_timeout = '5s';

-- Now this will fail fast if table is locked
ALTER TABLE bluebox.rental ADD COLUMN new_col INT;

-- ERROR: canceling statement due to lock timeout
```

---

[.footer: Slide 17 / 63]

## Monitor Postgres

- Catch problems before users notice
- Capacity planning
- Performance baselines
- Audit trails
- Sleep better at night

---

[.footer: Slide 18 / 63]

## What to Monitor

[.column]

### System Level
- CPU usage
- Memory usage
- Disk I/O
- Network
- Disk space

[.column]

### Postgres Level
- Connections
- Transaction rate
- Cache hit ratio
- Replication lag
- Locks

---

[.footer: Slide 19 / 63]

## Key Metrics to Watch

```sql
-- Connection count
SELECT count(*) FROM pg_stat_activity;

-- Database size growth
SELECT pg_database_size('bluebox');

-- Transaction rate (per second)
SELECT (xact_commit + xact_rollback) / extract(epoch from now() -  coalesce(stats_reset, 
(pg_catalog.pg_stat_file('base/' || datid || '/PG_VERSION')).modification)) AS tps
FROM pg_stat_database 
WHERE datname = 'bluebox';
```

---

[.footer: Slide 20 / 63]

## Cache Hit Ratio

```sql
SELECT 
    datname,
    ROUND(
        blks_hit::numeric / NULLIF(blks_hit + blks_read, 0) * 100, 
        2
    ) as cache_hit_ratio
FROM pg_stat_database
WHERE datname = 'bluebox';

-- Should be > 99% for OLTP workloads
```

---

[.footer: Slide 21 / 63]

## Monitoring Tools

| Open Source | Commercial |
|-------------|------------|
| pg\_stat\_monitor | pganalyze |
| Prometheus + postgres_exporter | Datadog |
| Grafana | New Relic |
| pgwatch2 | Sentry |
| pgmonitor ||

---

[.footer: Slide 22 / 63]

## Simple Health Check Query

```sql
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
    COALESCE(max(age(backend_xmin))::text, 'none')
FROM pg_stat_activity;
```

---

[.footer: Slide 23 / 63]

## Memory Configuration

![inline](../diagrams/shared buffers.png)

^ Judgment call: trimmed hard from hour-5. Just the handful of settings someone new to operating Postgres should know exist (shared_buffers, work_mem, maintenance_work_mem) - no effective_cache_size, buffer-cache internals, checkpoints, I/O cost tuning, or parallel query. Reading query plans (next section, from hour-6) is now the bigger focus for this audience than deep memory tuning.

---

[.footer: Slide 24 / 63]

## Shared Buffers

The database page cache - most important setting

```sql
-- Check current value
SHOW shared_buffers;

-- Set in postgresql.conf
shared_buffers = 8GB   -- For 32GB RAM system

-- Requires restart to change
```

**Rule of thumb**: Start with 25% of available RAM

---

[.footer: Slide 25 / 63]

## Shared Buffers Guidelines

| System RAM | shared_buffers |
|------------|----------------|
| 4GB | 1GB |
| 16GB | 4GB |
| 64GB | 16GB |
| 256GB | 32-64GB |

Beyond 32GB, diminishing returns - OS cache helps too

---

[.footer: Slide 26 / 63]

## What is work_mem?

Memory for query operations:

- Sorting (ORDER BY)
- Hash joins
- Hash aggregations
- Window functions

```sql
SHOW work_mem;  -- Default: 4MB
```

---

[.footer: Slide 27 / 63]

## Setting work_mem

**Be careful**: work_mem × connections × operations

```sql
-- Global setting (conservative)
work_mem = 64MB

-- Increase for specific session
SET work_mem = '256MB';
-- Run complex analytical query
RESET work_mem;
```

---

[.footer: Slide 28 / 63]

## When to Increase work_mem

Signs you need more:

```sql
-- Check for disk sorts
EXPLAIN (ANALYZE, BUFFERS) SELECT ...

-- Look for:
-- Sort Method: external merge  ← disk sort, increase work_mem
-- Sort Method: quicksort      ← memory sort, good!
```

^ This is the bridge into EXPLAIN, coming up next - "Sort Method" is something you'll actually see for yourself in a few slides.

---

[.footer: Slide 29 / 63]

## Maintenance Work Memory

Used by maintenance operations:

```sql
maintenance_work_mem = 1GB

-- Affects:
-- VACUUM
-- CREATE INDEX
-- ALTER TABLE ADD FOREIGN KEY
```

Can be set much higher than work_mem

---

[.footer: Slide 30 / 63]

## EXPLAIN - The Essential Tool

---

[.footer: Slide 31 / 63]

## What is EXPLAIN?

Shows you the query execution plan

```sql
EXPLAIN SELECT * FROM bluebox.film WHERE vote_average > 8;
```

Output:

```
                        QUERY PLAN                        
----------------------------------------------------------
 Seq Scan on film  (cost=0.00..941.95 rows=110 width=777)
   Filter: (vote_average > '8'::double precision)
```

---

[.footer: Slide 32 / 63]

## EXPLAIN Options

```sql
-- Basic plan (estimated only)
EXPLAIN SELECT * FROM bluebox.film WHERE vote_average > 8;

-- With actual execution times
EXPLAIN ANALYZE SELECT * FROM bluebox.film WHERE vote_average > 8;

-- With buffer/IO statistics
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM bluebox.film WHERE vote_average > 8;

-- All the details in text format
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT * FROM bluebox.film WHERE vote_average > 8;
```

---

[.footer: Slide 33 / 63]

## Reading Plan Costs

```
Seq Scan on film  (cost=0.00..941.95 rows=110 width=777)
                   ^^^^      ^^^^^^  ^^^^^^^^  ^^^^^^^^
                   startup   total   estimated row width
                   cost      cost    rows      in bytes
```

- **Cost**: Arbitrary units, relative comparison
- **Rows**: Estimated row count (110 films with rating > 8)
- **Width**: Average row size in bytes (777 bytes per film row)

---

[.footer: Slide 34 / 63]

## EXPLAIN ANALYZE

[.column]

![inline](../diagrams/explain analyze.png)

[.column]


Shows **actual** execution:

```sql
EXPLAIN ANALYZE 
SELECT * FROM bluebox.film WHERE vote_average > 8;
```

Estimated 110 rows, got 111 — pretty close!

---

[.footer: Slide 35 / 63]

## Warning About EXPLAIN ANALYZE

⚠️ **EXPLAIN ANALYZE actually runs the query!**

```sql
-- This will DELETE your data!
EXPLAIN ANALYZE DELETE FROM bluebox.customer;

-- Use ROLLBACK for data-modifying queries
BEGIN;
EXPLAIN ANALYZE DELETE FROM bluebox.customer;
ROLLBACK;
```

---

[.footer: Slide 36 / 63]

## EXPLAIN with BUFFERS

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM film WHERE vote_average > 8;
```

```
 Seq Scan on film  (cost=0.00..941.95 rows=110 width=777)
                   (actual time=0.034..5.966 rows=111 loops=1)
   Filter: (vote_average > '8'::double precision)
   Rows Removed by Filter: 7725
   Buffers: shared hit=844
 Planning Time: 1.264 ms
 Execution Time: 6.009 ms
```

- **shared hit=844**: 844 pages found in cache ✓
- **shared read**: Pages read from disk (none here!)

^ Callback to the Cache Hit Ratio slide from the Monitoring section - this is that same idea, one query at a time.

---

[.footer: Slide 37 / 63]

[.column]

## Common Plan Operations

[.column]

![inline](../diagrams/postgres-scan-types.png)

---

[.footer: Slide 38 / 63]

[.column]

## Sequential Scan

Reads every row in the table

**Good when**: Small tables, selecting most rows, no useful index

[.column]

![inline](../diagrams/seq-scan.png)

---

[.footer: Slide 39 / 63]

[.column]

## Index Scan

Uses index to find rows, then fetches from table

**Good when**: Selecting small percentage of rows, index matches conditions

[.column]

![inline](../diagrams/index-scan.png)

---

[.footer: Slide 40 / 63]

[.column]

## Index Only Scan

All needed data is in the index - no table access!

**Best case** - requires index covering all columns + recent vacuum

[.column]

![inline](../diagrams/index-only-scan.png)

---

[.footer: Slide 41 / 63]

[.column]

## Bitmap Scans

Two-phase: Build bitmap of matching rows, then fetch in physical order

**Good for**: Medium selectivity queries

[.column]

![inline](../diagrams/bitmap-index-scan.png)

---

[.footer: Slide 42 / 63]

## Join Operations - Nested Loop

```sql
EXPLAIN SELECT f.title, p.name FROM film f
JOIN film_cast fc ON f.film_id = fc.film_id
JOIN person p ON fc.person_id = p.person_id
WHERE f.film_id = 155;
```

```
Nested Loop  (actual time=0.10..0.16 rows=5)
  ->  Nested Loop  (actual time=0.08..0.08 rows=5)
        ->  Index Scan on film (film_id = 155)
        ->  Index Only Scan on film_cast
  ->  Index Scan on person
```

Best for small result sets with good indexes!

---

[.footer: Slide 43 / 63]

## Sort Methods in EXPLAIN

```
Sort  (cost=1200.00..1250.00 rows=10000)
  Sort Key: vote_average DESC
  Sort Method: quicksort  Memory: 1024kB
```

Or worse:

```
Sort  (cost=1200.00..1250.00 rows=10000)
  Sort Key: vote_average DESC
  Sort Method: external merge  Disk: 10240kB  ← BAD!
```

External merge = data exceeded work_mem

^ This is the payoff from the work_mem slides earlier - now you know where to look to confirm it.

---

[.footer: Slide 44 / 63]

## pg_stat_statements

---

[.footer: Slide 45 / 63]

## Finding Slow Queries

pg\_stat\_statements collects cumulative query statistics

```sql
-- Add to shared_preload_libraries
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
```

```bash
## Restart container to load the extension
docker compose down
docker compose --profile dba up -d
```

```sql
-- Then create the extension
CREATE EXTENSION pg_stat_statements;
```

---

[.footer: Slide 46 / 63]

## Top Queries by Total Time

```sql
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
```

^ Judgment call: this is a light touch of pg_stat_statements - just enough to answer "how would I even know what to run EXPLAIN on?" The fuller hour-6 treatment (generating activity, average time, I/O breakdown, resetting stats) and auto_explain are both cut here as more than this audience needs today.

---

[.footer: Slide 47 / 63]

![inline](../diagrams/postgres-index-types.png)

---

[.footer: Slide 48 / 63]

## B-Tree Index (Default)

Best for: Equality, ranges, sorting, LIKE with prefix

```sql
-- BEFORE: Check the plan without an index
EXPLAIN ANALYZE 
SELECT title FROM bluebox.film WHERE vote_average > 8;
-- Seq Scan on film  (cost=0.00..941.95)
--   Filter: (vote_average > 8)
```

---

[.footer: Slide 49 / 63]

## B-Tree Index: After

```sql
-- Create the index
CREATE INDEX idx_film_vote_avg ON bluebox.film(vote_average);

-- AFTER: Check the plan with the index
EXPLAIN ANALYZE 
SELECT title FROM bluebox.film WHERE vote_average > 8;
-- Bitmap Index Scan on idx_film_vote_avg  (cost=0.29..8.42)
--   Index Cond: (vote_average > 8)
```

Cost dropped from ~942 to ~8!

---

[.footer: Slide 50 / 63]

## GIN Index

Generalized Inverted Index - for arrays, JSONB, full-text

```sql
-- BEFORE: Full-text search without GIN index
EXPLAIN ANALYZE 
SELECT title FROM bluebox.film 
WHERE to_tsvector('english', overview) @@ to_tsquery('hero');
-- Seq Scan on film  (cost=0.00..2341.00)
--   Filter: (to_tsvector(...) @@ to_tsquery('hero'))
```

---

[.footer: Slide 51 / 63]

## GIN Index: After

```sql
-- Create GIN index on the text vector
CREATE INDEX idx_film_overview_gin ON bluebox.film 
USING gin(to_tsvector('english', overview));

-- AFTER: Same query with GIN index
EXPLAIN ANALYZE 
SELECT title FROM bluebox.film 
WHERE to_tsvector('english', overview) @@ to_tsquery('hero');
-- Bitmap Index Scan on idx_film_overview_gin  (cost=0.12..8.14)
```

Full-text search becomes instant!

---

[.footer: Slide 52 / 63]

## Index Type Summary

| Type | Use Case |
|------|----------|
| B-tree | General purpose (default) |
| GIN | JSONB, arrays, full-text |
| GiST | Geometry, ranges |
| Hash | Equality only (rare) |
| BRIN | Time-series, ordered data |

^ Judgment call: composite/covering/partial/expression index strategies and HypoPG (testing
hypothetical indexes) from hour-6 are cut here - solid "part two" material once this audience is
past the basics of what an index even is and how to read its effect in EXPLAIN.

---

[.footer: Slide 53 / 63]

## When NOT to Index

- Small tables (seq scan is fine)
- Columns rarely in WHERE/JOIN/ORDER BY
- Low cardinality columns (few distinct values)
- Write-heavy tables with few reads

Every index has maintenance cost!

---

[.footer: Slide 54 / 63]

## Finding Missing Indexes

```sql
-- Tables with high sequential scan ratio
SELECT 
    schemaname, relname,
    seq_scan, idx_scan,
    ROUND(100.0 * seq_scan / NULLIF(seq_scan + idx_scan, 0), 2) as seq_pct
FROM pg_stat_user_tables
WHERE seq_scan + idx_scan > 1000
ORDER BY seq_scan DESC
LIMIT 10;
```

---

[.footer: Slide 55 / 63]

## Common Performance Patterns

---

[.footer: Slide 56 / 63]

## Pattern: N+1 Queries

**Problem**: Loop making individual queries

```python
## BAD: N+1 queries
for customer in get_customers():
    rentals = query(f"SELECT * FROM rental WHERE customer_id = {customer.id}")
```

**Solution**: Single query with JOIN

```sql
-- GOOD: Single query
SELECT c.*, r.* 
FROM customer c 
LEFT JOIN rental r ON c.customer_id = r.customer_id;
```

---

[.footer: Slide 57 / 63]

## Pattern: SELECT *

**Problem**: Fetching unnecessary columns

```sql
-- BAD: Gets all columns
SELECT * FROM bluebox.film WHERE vote_average > 8;
```

**Solution**: Select only needed columns

```sql
-- GOOD: Only needed columns
SELECT film_id, title, vote_average 
FROM bluebox.film 
WHERE vote_average > 8;
```

---

[.footer: Slide 58 / 63]

## Pattern: OFFSET for Pagination

**Problem**: OFFSET scans and discards rows

```sql
-- BAD: Must scan 10000 rows to skip them
SELECT * FROM bluebox.rental 
ORDER BY rental_id 
OFFSET 10000 LIMIT 20;
```

**Solution**: Keyset pagination

```sql
-- GOOD: Use index
SELECT * FROM bluebox.rental 
WHERE rental_id > 10000 
ORDER BY rental_id 
LIMIT 20;
```

---

[.footer: Slide 59 / 63]

## Pattern: Functions on Indexed Columns

**Problem**: Function prevents index use

```sql
-- BAD: Can't use index efficiently  
SELECT * FROM bluebox.payment 
WHERE DATE(payment_date) = '2024-01-15';
```

**Solution**: Rewrite condition

```sql
-- GOOD: Can use index
SELECT * FROM bluebox.payment 
WHERE payment_date >= '2024-01-15' 
  AND payment_date < '2024-01-16';
```

---

[.footer: Slide 60 / 63]

## Pattern: OR Conditions

**Problem**: OR can prevent index use

```sql
-- Might not use index efficiently
SELECT * FROM bluebox.film 
WHERE vote_average = 8 OR EXTRACT(year FROM release_date) = 2024;
```

**Solution**: Use UNION

```sql
-- Each part can use its own index
SELECT * FROM bluebox.film WHERE vote_average = 8
UNION
SELECT * FROM bluebox.film WHERE EXTRACT(year FROM release_date) = 2024;
```

---

[.footer: Slide 61 / 63]

## Query Tuning Checklist

1. ✅ Use EXPLAIN (ANALYZE, BUFFERS) to understand plans
2. ✅ Check pg\_stat\_statements for slow queries
3. ✅ Ensure appropriate indexes exist
4. ✅ Look for sequential scans on large tables
5. ✅ Watch for disk sorts (increase work_mem)
6. ✅ Verify statistics are current (ANALYZE)
7. ✅ Consider covering indexes for frequent queries

---

[.footer: Slide 62 / 63]

## Session 3 Summary

- ✅ Diagnosing locks and blocking sessions
- ✅ Finding and stopping runaway queries, timeouts as guardrails
- ✅ Monitoring essentials and key metrics
- ✅ A few key memory settings: shared_buffers, work_mem
- ✅ Reading query plans with EXPLAIN
- ✅ Index basics and when (not) to add one
- ✅ Common performance anti-patterns and fixes

This is a diagnostic checklist and a first pass at reading query plans - not deep tuning mastery.

---

[.footer: Slide 63 / 63]

## Questions?

<br>
<br>

## That Wraps the Series! Bluebox Stays Up
### Keep exploring locks, monitoring, EXPLAIN, and indexes on your own
