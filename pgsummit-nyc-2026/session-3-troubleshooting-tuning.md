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

[.footer: Slide 1 / 56]

## When Postgres Misbehaves
### Locks, Monitoring, Key Config & Reading Query Plans
<br>
<br>
## Session 3 of 3 — Beginning Postgres Workshop
### PGSummit NYC 2026

^ WIP session assembled from hour-4-troubleshooting.md (locks + monitoring only), hour-5-performance.md (a few key memory settings only), and hour-6-query-tuning.md (EXPLAIN, index basics, common patterns) for PGSummit NYC. This is now the largest of the three sessions - per updated guidance, it leans much more on hour-6's EXPLAIN/index content than on hour-5's deep memory tuning, since a diagnostic mental model matters more to this audience than tuning depth. Talking/demo-led, not hands-on. See pgsummit-nyc-2026/README.md.

---

[.footer: Slide 2 / 56]

## Session 3 Topics

- Locks & blocking, with a live demo
- Finding and stopping bad queries, timeouts as guardrails
- Monitoring essentials and `pg_stat_statements`
- A few key config settings (`shared_buffers`, `work_mem`)
- Reading query plans with EXPLAIN
- Index basics and common performance patterns

---

[.footer: Slide 3 / 56]

## Locks, Blocking & Runaway Queries

---

[.footer: Slide 4 / 56]

## Common Problems

- Long-running queries blocking others
- Idle transactions holding locks
- Runaway queries consuming resources
- Connection exhaustion
- Lock contention

---

[.footer: Slide 5 / 56]

![fit](../diagrams/lock-types.png)

---

[.footer: Slide 6 / 56]

## 🔧 Demo: Create a Blocking Lock

[.column]

**Window 1**

```sql
BEGIN;
UPDATE bluebox.film
SET popularity = popularity
WHERE film_id = 155;
-- no COMMIT yet: this session is
-- now "idle in transaction"
```

[.column]

**Window 2**

```sql
UPDATE bluebox.film
SET popularity = popularity
WHERE film_id = 155;
-- hangs: waiting for window 1's
-- row lock
```

Find the blocker from a third window (next slide). `ROLLBACK` in window 1 and window 2 finishes instantly.

^ Three psql sessions side by side. Both UPDATEs write the same value back, so the demo leaves Bluebox unchanged.

---

[.footer: Slide 7 / 56]

## Who Is Blocking Whom?

```sql
SELECT pid,
       pg_blocking_pids(pid) AS blocked_by,
       wait_event_type,
       NOW() - query_start AS waiting,
       LEFT(query, 40) AS query
FROM pg_stat_activity
WHERE cardinality(pg_blocking_pids(pid)) > 0;
```

```
 pid | blocked_by | wait_event_type |     waiting     |                  query                   
-----+------------+-----------------+-----------------+------------------------------------------
 166 | {164}      | Lock            | 00:00:02.104775 | UPDATE bluebox.film SET popularity = pop
```

Look up pid 164 in `pg_stat_activity`: it's window 1, `idle in transaction`. That pid is what we cancel or terminate in a moment.

^ One query instead of the three lock queries from hour-4 (raw `pg_locks`, the recursive "source of the lock" query, and the `pg_locks` self-join): `pg_blocking_pids()` does the `pg_locks` work for you and also catches row and transaction locks. Passing mention: if you want to see lock waits show up in the Postgres log automatically, `log_lock_waits` will do that - detailed logging configuration is out of scope for this session.

---

[.footer: Slide 8 / 56]

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

[.footer: Slide 9 / 56]

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

[.footer: Slide 10 / 56]

## Canceling a Query

```sql
-- Cancel the current query (graceful)
SELECT pg_cancel_backend(12345);

-- Returns true if signal sent successfully
```

The query receives an interrupt and can clean up

---

[.footer: Slide 11 / 56]

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

[.footer: Slide 12 / 56]

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

[.footer: Slide 13 / 56]

## Idle Transaction Timeout

Kill sessions that sit idle in a transaction

```sql
-- postgresql.conf or per-session
idle_in_transaction_session_timeout = '10min'

-- Per user
ALTER ROLE app_user SET idle_in_transaction_session_timeout = '5min';
```

---

[.footer: Slide 14 / 56]

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

[.footer: Slide 15 / 56]

## Monitor Postgres

- Catch problems before users notice
- Capacity planning
- Performance baselines
- Audit trails
- Sleep better at night

---

[.footer: Slide 16 / 56]

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

[.footer: Slide 17 / 56]

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

[.footer: Slide 18 / 56]

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

[.footer: Slide 19 / 56]

## Monitoring Tools

| Open Source | Commercial |
|-------------|------------|
| pg\_stat\_monitor | pganalyze |
| Prometheus + postgres_exporter | Datadog |
| Grafana | New Relic |
| pgwatch | |
| pgmonitor | |

---

[.footer: Slide 20 / 56]

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
    COALESCE(max(NOW() - xact_start)::text, 'none')
FROM pg_stat_activity;
```

---

[.footer: Slide 21 / 56]

## `pg_stat_statements`: Finding Slow Queries

Tracks every query shape: calls, total and average time. It needs `shared_preload_libraries` (our `docker-compose.yml` preloads it; on your own server, set it and restart).

```sql
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
```

The top of this list is what you EXPLAIN - right after a few memory settings.

^ Judgment call: this is a light touch of `pg_stat_statements` - just enough to answer "how would I even know what to run EXPLAIN on?", so it now sits with monitoring, before EXPLAIN. Preloading it in docker-compose.yml means no container restart mid-talk. The fuller hour-6 treatment (generating activity, average time, I/O breakdown, resetting stats) and `auto_explain` are both cut here as more than this audience needs today.

---

[.footer: Slide 22 / 56]

## Memory Configuration

![inline](../diagrams/shared buffers.png)

^ Judgment call: trimmed hard from hour-5. Just the handful of settings someone new to operating Postgres should know exist (`shared_buffers`, `work_mem`, `maintenance_work_mem`) - no `effective_cache_size`, buffer-cache internals, checkpoints, I/O cost tuning, or parallel query. Reading query plans (next section, from hour-6) is now the bigger focus for this audience than deep memory tuning.

---

[.footer: Slide 23 / 56]

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

[.footer: Slide 24 / 56]

## Shared Buffers Guidelines

| System RAM | shared_buffers |
|------------|----------------|
| 4GB | 1GB |
| 16GB | 4GB |
| 64GB | 16GB |
| 256GB | 32-64GB |

Beyond 32GB, diminishing returns - OS cache helps too

---

[.footer: Slide 25 / 56]

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

[.footer: Slide 26 / 56]

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

[.footer: Slide 27 / 56]

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

[.footer: Slide 28 / 56]

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

[.footer: Slide 29 / 56]

## EXPLAIN - The Essential Tool

---

[.footer: Slide 30 / 56]

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

[.footer: Slide 31 / 56]

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

[.footer: Slide 32 / 56]

## Reading Plan Costs

```
Seq Scan on film  (cost=0.00..941.95 rows=110 width=777)
                   ^^^^      ^^^^^^  ^^^^^^^^  ^^^^^^^^
                   startup   total   estimated row width
                   cost      cost    rows      in bytes
```

- **Cost**: Arbitrary units, relative comparison
- **Rows**: Estimated row count from table statistics (110 films with vote_average > 8; ANALYZE and autovacuum keep these fresh)
- **Width**: Average row size in bytes (777 bytes per film row)

---

[.footer: Slide 33 / 56]

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

[.footer: Slide 34 / 56]

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

[.footer: Slide 35 / 56]

## EXPLAIN with BUFFERS

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM bluebox.film WHERE vote_average > 8;
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

[.footer: Slide 36 / 56]

[.column]

## Common Plan Operations

[.column]

![inline](../diagrams/postgres-scan-types.png)

---

[.footer: Slide 37 / 56]

[.column]

## Sequential Scan

Reads every row in the table

**Good when**: Small tables, selecting most rows, no useful index

[.column]

![inline](../diagrams/seq-scan.png)

---

[.footer: Slide 38 / 56]

[.column]

## Index Scan

Uses index to find rows, then fetches from table

**Good when**: Selecting small percentage of rows, index matches conditions

[.column]

![inline](../diagrams/index-scan.png)

---

[.footer: Slide 39 / 56]

[.column]

## Index Only Scan

All needed data is in the index - no table access!

**Best case** - requires index covering all columns + recent vacuum

[.column]

![inline](../diagrams/index-only-scan.png)

---

[.footer: Slide 40 / 56]

[.column]

## Bitmap Scans

Two-phase: Build bitmap of matching rows, then fetch in physical order

**Good for**: Medium selectivity queries

[.column]

![inline](../diagrams/bitmap-index-scan.png)

---

[.footer: Slide 41 / 56]

## Join Operations - Nested Loop

```sql
EXPLAIN SELECT f.title, p.name FROM bluebox.film f
JOIN bluebox.film_cast fc ON f.film_id = fc.film_id
JOIN bluebox.person p ON fc.person_id = p.person_id
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

[.footer: Slide 42 / 56]

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

[.footer: Slide 43 / 56]

## Indexes

---

[.footer: Slide 44 / 56]

![inline](../diagrams/postgres-index-types.png)

---

[.footer: Slide 45 / 56]

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

[.footer: Slide 46 / 56]

## B-Tree Index: After

```sql
-- Create the index
CREATE INDEX idx_film_vote_avg ON bluebox.film(vote_average);

-- AFTER: Check the plan with the index
EXPLAIN ANALYZE 
SELECT title FROM bluebox.film WHERE vote_average > 8;
-- Bitmap Heap Scan on film  (cost=5.13..308.25 rows=110)
--   Recheck Cond: (vote_average > 8)
--   ->  Bitmap Index Scan on idx_film_vote_avg  (cost=0.00..5.11 rows=110)
--         Index Cond: (vote_average > 8)
```

Total cost dropped from ~942 to ~308. Read the top node: the index lookup itself is ~5, fetching the ~100 matching table pages is the rest.

^ Plan captured on a fresh Bluebox load (PG 18.6); exact costs vary a little with table size.

---

[.footer: Slide 47 / 56]

## Index Type Summary

| Type | Use Case |
|------|----------|
| B-tree | General purpose (default) |
| GIN | JSONB, arrays, full-text |
| GiST | Geometry, ranges |
| Hash | Equality only (rare) |
| BRIN | Time-series, ordered data |

^ Judgment call: composite/covering/partial/expression index strategies and HypoPG (testing
hypothetical indexes) from hour-6 are cut here - solid follow-up material once this audience is
past the basics of what an index even is and how to read its effect in EXPLAIN. The GIN
before/after pair and "Finding Missing Indexes" were also cut for time; both are in hour-6-query-tuning.md.

---

[.footer: Slide 48 / 56]

## When NOT to Index

- Small tables (seq scan is fine)
- Columns rarely in WHERE/JOIN/ORDER BY
- Low cardinality columns (few distinct values)
- Write-heavy tables with few reads

Every index has maintenance cost!

---

[.footer: Slide 49 / 56]

## Common Performance Patterns

---

[.footer: Slide 50 / 56]

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

[.footer: Slide 51 / 56]

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

[.footer: Slide 52 / 56]

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

[.footer: Slide 53 / 56]

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

[.footer: Slide 54 / 56]

## Query Tuning Checklist

1. ✅ Check pg\_stat\_statements for slow queries
2. ✅ Use EXPLAIN (ANALYZE, BUFFERS) to understand plans
3. ✅ Ensure appropriate indexes exist
4. ✅ Look for sequential scans on large tables
5. ✅ Watch for disk sorts (increase work_mem)
6. ✅ Verify statistics are current (ANALYZE)

---

[.footer: Slide 55 / 56]

## Session 3 Summary

- ✅ Diagnosing locks and blocking sessions
- ✅ Finding and stopping runaway queries, timeouts as guardrails
- ✅ Monitoring essentials, key metrics and `pg_stat_statements`
- ✅ A few key memory settings: `shared_buffers`, `work_mem`
- ✅ Reading query plans with EXPLAIN
- ✅ Index basics and when (not) to add one
- ✅ Common performance anti-patterns and fixes

This is a diagnostic checklist and a first pass at reading query plans - not deep tuning mastery.

---

[.footer: Slide 56 / 56]

## Questions?

<br>
<br>

## That Wraps the Series! Bluebox Stays Up
### Keep exploring locks, monitoring, EXPLAIN, and indexes on your own
