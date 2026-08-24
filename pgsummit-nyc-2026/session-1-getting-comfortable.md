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

[.footer: Slide 1 / 50]

## Getting Comfortable with Postgres
### Tools, Users, Schemas, Objects, Arrays, JSONB & Window Functions
<br>
<br>
## Session 1 of 3 — Beginning Postgres Workshop
### PGSummit NYC 2026

^ WIP session assembled from hour-1-beginner.md and hour-2-sql.md for PGSummit NYC. This is a
talking/demo-led session, not hands-on lab work — a separate session-0-setup.md is what we send
people to ahead of time (or point to on-site) for the Docker/psql/Bluebox setup steps, so none of
that is repeated here. See pgsummit-nyc-2026/README.md for open questions before finalizing.

---

[.footer: Slide 2 / 50]

## Session 1 Topics

- Tools for querying Postgres
- Users, roles & permissions
- Schemas
- Data types & building objects (with a live demo)
- Arrays and JSON
- Window functions

^ Setup (Docker, psql install, loading Bluebox) isn't covered here — see session-0-setup.md if you
need to get the environment running again.

---

[.footer: Slide 3 / 50]

## Tools for Querying Postgres

---

[.footer: Slide 4 / 50]

## GUI Tools

[.column]

### pgAdmin
- Official GUI tool
- Web-based interface
- Free and open source

[.column]

### DBeaver
- Multi-database support
- ER diagrams
- Free community edition

^ Feel free to use your own tool here.

---

[.footer: Slide 5 / 50]

## psql - The Postgres CLI

The most powerful way to interact with Postgres

```
psql (18.x)
Type "help" for help.

bluebox=#
```

---

[.footer: Slide 6 / 50]

## Essential psql Commands

| Command | Description |
|---------|-------------|
| `\l` | List all databases |
| `\c dbname` | Connect to database |
| `\dt` | List tables |
| `\d tablename` | Describe table |
| `\dn` | List schemas |

* `\d` stands for "describe"

---

[.footer: Slide 7 / 50]

## Expanded Display: \x auto

```sql
\x auto   -- Let psql decide (recommended!)
\x on     -- Always record
\x off    -- Always horizontal (default)
```

Expanded view shows one column per line:

```
-[ RECORD 1 ]----------------
id    | 1
name  | Alice
email | alice@test.com
```

**Pro tip**: Put `\x auto` in your `~/.psqlrc` file!

---

[.footer: Slide 8 / 50]

## More Useful psql Settings

```sql
\timing              -- Show query execution time
\conninfo            -- Show current connection info
\pset pager off      -- Turn off page-by-page scrolling
```

```
bluebox=# \timing
Timing is on.
bluebox=# SELECT COUNT(*) FROM film;
 count 
-------
  7836
(1 row)
Time: 2.145 ms

bluebox=# \conninfo
You are connected to database "bluebox" as user "postgres" 
on host "localhost" at port "5432".
```

---

[.footer: Slide 9 / 50]

## Users and Permissions

---

[.footer: Slide 10 / 50]

## Postgres Roles

In Postgres, **users** and **groups** are both **roles**

```sql
-- Create a user (role with login)
CREATE ROLE app_user WITH LOGIN PASSWORD 'secure_password';

-- Create a group (role without login)
CREATE ROLE readonly;
```

---

[.footer: Slide 11 / 50]

## Role Attributes

```sql
CREATE ROLE app_user WITH 
  LOGIN 
  PASSWORD 'secure_password'
  CREATEDB 
  CREATEROLE;
```

Common attributes:
- `LOGIN` / `NOLOGIN`
- `SUPERUSER` / `NOSUPERUSER`
- `CREATEDB` / `NOCREATEDB`
- `CREATEROLE` / `NOCREATEROLE`

---

[.footer: Slide 12 / 50]

## Granting Privileges

```sql
-- Grant connection to database
GRANT CONNECT ON DATABASE bluebox TO app_user;

-- Grant schema usage
GRANT USAGE ON SCHEMA bluebox TO app_user;

-- Grant table privileges
GRANT SELECT ON ALL TABLES IN SCHEMA bluebox TO app_user;

-- Grant specific privileges
GRANT SELECT, INSERT, UPDATE ON bluebox.rental TO app_user;
```

---

[.footer: Slide 13 / 50]

## Manage Privileges with Groups

Roles can be members of other roles (like groups!)

```sql
-- Create a group role for data analytics team
CREATE ROLE data_analytics NOLOGIN;

-- Grant read access on Bluebox to the group
GRANT CONNECT ON DATABASE bluebox TO data_analytics;
GRANT USAGE ON SCHEMA bluebox TO data_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA bluebox TO data_analytics;
```

---

[.footer: Slide 14 / 50]

## Grant Users Role Membership

```sql
-- Create a user for an analyst
CREATE ROLE maria LOGIN;
\password maria

-- Add maria to the data_analytics group
GRANT data_analytics TO maria;

-- Maria now inherits all permissions from data_analytics!
```

---

[.footer: Slide 15 / 50]

## View Role Memberships

```sql
\du
```

```
                             List of roles
   Role name    |         Attributes          |   Member of    
----------------+-----------------------------+----------------
 data_analytics | Cannot login                | {}
 maria          |                             | {data_analytics}
 app_user       |                             | {}
 postgres       | Superuser, Create role, ... | {}
```

Maria is a member of `data_analytics` - she inherits its permissions!

^ Password creation/hashing details (SCRAM-SHA-256, \password, MD5 migration) are skipped in this
session — good material for a deeper security-focused talk, but more than this audience needs today.

---

[.footer: Slide 16 / 50]

## Schemas

![inline](../diagrams/instance-cluster-schema.png)

---

[.footer: Slide 17 / 50]

## What is a Schema?

A **schema** is a namespace within a database

- Organizes database objects (tables, views, functions)
- Provides access control boundaries
- Avoids naming conflicts

---

[.footer: Slide 18 / 50]

## Default Schema

```sql
-- The default schema is 'public'
CREATE TABLE my_table (id int);

-- Same as:
CREATE TABLE public.my_table (id int);
```

---

[.footer: Slide 19 / 50]

## Creating Schemas

```sql
-- Bluebox already has its schema, but you could create more:
CREATE SCHEMA reporting;

-- Then create tables in that schema
CREATE TABLE reporting.daily_stats (...);
```

Bluebox uses `bluebox` schema to organize all its tables

---

[.footer: Slide 20 / 50]

## Schema Search Path

```sql
-- View current search path
SHOW search_path;
-- Output: "$user", public

-- Set search path
SET search_path TO bluebox, public;

-- Now queries will look in bluebox first
SELECT * FROM film;  -- Same as bluebox.film
```

---

[.footer: Slide 21 / 50]

## Bluebox Schema

The Bluebox database uses a `bluebox` schema with 17 tables:

```sql
SET search_path TO bluebox, public;
\dt
```

```
 Schema  |        tablename        
---------+-------------------------
 bluebox | customer      (186,740 rows)
 bluebox | film          (7,836 rows)
 bluebox | person        (258,772 rows)
 bluebox | store         (196 rows)
 ...and 13 more tables
```

---

[.footer: Slide 22 / 50]

## ALTER User Search Path

```sql
-- Set search path
ALTER USER maria SET search_path TO bluebox, public;

-- From next login, queries will look in bluebox first
SELECT * FROM film;  -- Same as bluebox.film
```

---

[.footer: Slide 23 / 50]

## Object and Data Types

---

[.footer: Slide 24 / 50]

## Database Objects

- **Tables** - Store data in rows and columns
- **Views** - Saved queries that act like tables
- **Indexes** - Speed up data retrieval
- **Sequences** - Auto-incrementing number generators
- **Functions** - Reusable SQL/procedural code

---

[.footer: Slide 25 / 50]

## Common Data Types

[.column]

Numeric
- `INTEGER` / `BIGINT`
- `NUMERIC(p,s)`
- `REAL` / `DOUBLE`

Character
- `TEXT` (preferred)
- `VARCHAR(n)`

[.column]

Date/Time
- `DATE` / `TIME`
- `TIMESTAMP`
- `TIMESTAMPTZ` ⭐
- `INTERVAL`

Other
- `BOOLEAN`
- `UUID`
- `JSON` / `JSONB`
- array of any other type, e.g. `int[]`, `text[]`

---

[.footer: Slide 26 / 50]

## ⏰ Time: Use TIMESTAMPTZ!

`TIMESTAMP` vs `TIMESTAMPTZ` - always prefer **TIMESTAMPTZ**

```sql
-- TIMESTAMP: No timezone info (dangerous!)
CREATE TABLE events (event_time TIMESTAMP);

-- TIMESTAMPTZ: Stores in UTC, converts on display ✓
CREATE TABLE events (event_time TIMESTAMPTZ);
```

```sql
-- What time is it?
SELECT NOW();  -- 2026-01-16 10:30:00-08
```

TIMESTAMPTZ handles daylight saving automatically!

---

[.footer: Slide 27 / 50]

## 💰 Use NUMERIC, Not MONEY!

```sql
-- DON'T use the MONEY type
price MONEY  -- ❌ Locale-dependent, rounding issues

-- DO use NUMERIC for currency
price NUMERIC(10,2)  -- ✓ Exact precision, no surprises
```

Bluebox uses `NUMERIC` for payment amounts:

```sql
SELECT amount FROM bluebox.payment LIMIT 3;
```

```
 amount 
--------
   1.99
   1.99
   3.98
```

NUMERIC stores exact values - no floating point errors!

---

[.footer: Slide 28 / 50]

## 🎯 Custom Data Types: ENUM

Postgres lets you create custom types!

Bluebox uses an ENUM for MPAA ratings:

```sql
CREATE TYPE mpaa_rating AS ENUM (
    'G', 'PG', 'PG-13', 'R', 'NC-17', 'NR'
);

-- Used in the film table
SELECT title, rating FROM bluebox.film 
WHERE rating = 'PG-13' LIMIT 3;
```

```
                 title                 | rating 
---------------------------------------+--------
 Are You There God? It's Me, Margaret. | PG-13
 Love at First Sight                   | PG-13
 Batman Returns                        | PG-13
```

---

[.footer: Slide 29 / 50]

## Creating a Table

Let's add a customer reviews feature to Bluebox!

```sql
CREATE TABLE bluebox.customer_review (
    review_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES bluebox.customer(customer_id),
    film_id BIGINT REFERENCES bluebox.film(film_id),
    rating SMALLINT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

^ Live demo starts here: create the table, then add data to it live for the next several slides.

---

[.footer: Slide 30 / 50]

## 🔧 Demo: Add Yourself as a Customer

```sql
-- Add yourself to the Bluebox database
INSERT INTO bluebox.customer 
    (customer_id, store_id, full_name, email)
VALUES (
    (SELECT MAX(customer_id) + 1 FROM bluebox.customer),
    1,                          -- Store #1
    'Your Name Here',           -- Your name!
    'you@example.com'
)
RETURNING customer_id, full_name;
```

```
 customer_id |   full_name    
-------------+----------------
      205026 | Your Name Here   ← Save this ID!
```

Note: this is a great use of the Postgres feature `RETURNING`

---

[.footer: Slide 31 / 50]

## 🔧 Demo: Find Films to Review

```sql
-- Find some popular films to review
SELECT film_id, title FROM bluebox.film 
WHERE title IN ('The Dark Knight', 'Inception', 
                'Interstellar', 'Dune: Part Two');
```

```
 film_id |      title      
---------+-----------------
     155 | The Dark Knight
   27205 | Inception
  157336 | Interstellar
  693134 | Dune: Part Two
```

---

[.footer: Slide 32 / 50]

## 🔧 Demo: Insert Your Reviews

Replace `205026` with your actual customer_id!

```sql
-- Use YOUR customer_id from the previous step!
INSERT INTO bluebox.customer_review 
    (customer_id, film_id, rating, review_text)
VALUES 
    (205026, 155, 5, 'Heath Ledger was incredible!'),
    (205026, 27205, 5, 'Mind-bending! Had to watch twice'),
    (205026, 693134, 5, 'Even better than the first Dune!');
```

---

[.footer: Slide 33 / 50]

## 🔧 Demo: Querying Your Reviews

```sql
-- See your reviews with a JOIN
SELECT c.full_name, f.title, r.rating, 
       LEFT(r.review_text, 30) as review
FROM bluebox.customer_review r
JOIN bluebox.customer c ON r.customer_id = c.customer_id
JOIN bluebox.film f ON r.film_id = f.film_id
ORDER BY r.created_at DESC;
```

```
   full_name    |      title      | rating |           review            
----------------+-----------------+--------+-----------------------------
 Your Name      | The Dark Knight |      5 | Heath Ledger was incredible
 Your Name      | Inception       |      5 | Mind-bending! Had to watch 
 Your Name      | Dune: Part Two  |      5 | Even better than the first
```

---

[.footer: Slide 34 / 50]

## Bluebox Tables

```sql
\d bluebox.film
```

```
      Column       |    Type     |          Description
-------------------+-------------+---------------------------
 film_id           | bigint      | Primary key
 title             | text        | Movie title
 overview          | text        | Plot summary
 release_date      | date        | Release date
 vote_average      | real        | TMDB rating (0-10)
 popularity        | real        | TMDB popularity score
 budget            | bigint      | Production budget
 revenue           | bigint      | Box office revenue
```

---

[.footer: Slide 35 / 50]

## Arrays and JSON

---

[.footer: Slide 36 / 50]

## Arrays in PostgreSQL

Bluebox stores genre IDs as an array on each film:

```sql
SELECT film_id, title, genre_ids 
FROM bluebox.film 
WHERE title = 'The Dark Knight';
```

```
 film_id |      title      |   genre_ids   
---------+-----------------+---------------
     155 | The Dark Knight | {18,28,80,53}
```

```sql
-- What do these IDs mean? Check the film_genre table
SELECT genre_id, name FROM bluebox.film_genre 
WHERE genre_id IN (18, 28, 80, 53);
```

Drama (18), Action (28), Crime (80), Thriller (53)

---

[.footer: Slide 37 / 50]

## Adding to an Array

```sql
-- Add a genre to a film's array
UPDATE bluebox.film
SET genre_ids = genre_ids || ARRAY[9648]  -- Add Mystery
WHERE film_id = 155;

-- Alternative: array_append function
UPDATE bluebox.film
SET genre_ids = array_append(genre_ids, 9648)
WHERE film_id = 155;
```

---

[.footer: Slide 38 / 50]

## Array Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `= ANY()` | Contains value | `28 = ANY(genre_ids)` |
| `@>` | Contains all | `genre_ids @> ARRAY[28,80]` |
| `<@` | Is contained by | `ARRAY[28] <@ genre_ids` |
| `&&` | Overlaps (any match) | `genre_ids && ARRAY[28,35]` |
| (double pipe) | Concatenate | `genre_ids` + `ARRAY[9648]` |
| `[n]` | Access element | `genre_ids[1]` (1-indexed!) |

---

[.footer: Slide 39 / 50]

## Querying Arrays

```sql
-- Find Action films
-- = ANY() checks if value exists anywhere in the array
SELECT f.title
FROM bluebox.film f
JOIN bluebox.film_genre fg ON fg.genre_id = ANY(f.genre_ids)
WHERE fg.name = 'Action'
LIMIT 3;

-- Find films that are both Action AND Crime
-- @> checks if array contains ALL specified values
SELECT title FROM bluebox.film f
WHERE genre_ids @> ARRAY(
    SELECT genre_id FROM bluebox.film_genre 
    WHERE name IN ('Action', 'Crime')
) LIMIT 3;

-- Unnest: expand array to rows (list all genres for a film)
SELECT f.title, g.name as genre
FROM bluebox.film f, unnest(f.genre_ids) as gid
JOIN bluebox.film_genre g ON g.genre_id = gid
WHERE f.title = 'The Dark Knight';
```

---

[.footer: Slide 40 / 50]

## JSON vs JSONB

| Feature | JSON | JSONB |
|---------|------|-------|
| Storage | Text (as-is) | Binary (parsed) |
| Insert speed | Faster | Slower |
| Query speed | Slower | **Much faster** |
| Indexing | ❌ No | ✅ GIN indexes |
| Preserves order | ✅ Yes | ❌ No |
| Duplicate keys | Preserved | Last value wins |

**Always use JSONB** unless you need exact JSON preservation

---

[.footer: Slide 41 / 50]

## Working with JSONB

[.column]

```sql
-- Create table with JSONB
CREATE TABLE movie_metadata (
    movie_id INT PRIMARY KEY,
    data JSONB
);

-- Insert JSON data
INSERT INTO movie_metadata (movie_id, data)
VALUES (1, '{
    "director": "Christopher Nolan",
    "budget": 160000000,
    "awards": ["Oscar", "BAFTA"]
}');


[.column]

-- Different row, completely different structure - that's OK!
INSERT INTO movie_metadata (movie_id, data)
VALUES (2, '{
    "streaming": ["Netflix", "Hulu"],
    "runtime_minutes": 148,
    "has_sequel": true
}');
```

No schema enforcement - each row can have different structures!

---

[.footer: Slide 42 / 50]

## JSONB Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `->` | Get as JSON | `data->'awards'` |
| `->>` | Get as TEXT | `data->>'director'` |
| `#>` | Get path as JSON | `data#>'{awards,0}'` |
| `#>>` | Get path as TEXT | `data#>>'{awards,0}'` |
| `?` | Key exists? | `data ? 'budget'` |
| `?&` | All keys exist? | `data ?& array['a','b']` |
| `@>` | Contains? | `data @> '{"x":1}'` |

---

[.footer: Slide 43 / 50]

## Querying JSONB

```sql
-- Extract value as text (most common)
SELECT data->>'director' as director
FROM movie_metadata;

-- Extract nested value (awards array, first item)
SELECT data->'awards'->>0 as first_award
FROM movie_metadata;

-- Check if key exists
SELECT * FROM movie_metadata
WHERE data ? 'budget';

-- Query by JSON value (containment)
SELECT * FROM movie_metadata
WHERE data @> '{"director": "Christopher Nolan"}';
```

---

[.footer: Slide 44 / 50]

## Window Functions

Perform calculations across related rows **without grouping**

- **Running totals** - cumulative sums as you go down rows
- **LAG / LEAD** - access previous or next row's values
- **ROW_NUMBER** - assign sequential numbers to rows
- **RANK / DENSE_RANK** - rank rows with tie handling
- **PARTITION BY** - restart calculations for each group

Key difference from GROUP BY: window functions keep all rows!

---

[.footer: Slide 45 / 50]

![fit](../diagrams/window-functions.png)

---

[.footer: Slide 46 / 50]

## Running Totals

```sql
SELECT 
    payment_date::date,
    amount,
    SUM(amount) OVER (
        ORDER BY payment_date
    ) as running_total
FROM bluebox.payment
WHERE customer_id = 53853
ORDER BY payment_date;
```

```
 payment_date | amount | running_total 
--------------+--------+---------------
 2025-03-05   |   1.99 |          1.99
 2025-06-07   |   7.96 |          9.95
 2025-06-28   |   7.96 |         17.91
```

---

[.footer: Slide 47 / 50]

## LAG - Compare to Previous Row

```sql
SELECT 
    payment_date::date,
    amount,
    LAG(amount) OVER (ORDER BY payment_date) as prev_amount,
    amount - LAG(amount) OVER (ORDER BY payment_date) as difference
FROM bluebox.payment
WHERE customer_id = 53853
ORDER BY payment_date;
```

```
 payment_date | amount | prev_amount | difference 
--------------+--------+-------------+------------
 2025-03-05   |   1.99 |      [NULL] |     [NULL]
 2025-06-07   |   7.96 |        1.99 |       5.97
 2025-06-28   |   7.96 |        7.96 |       0.00
```

---

[.footer: Slide 48 / 50]

## LEAD - Look Ahead

```sql
SELECT 
    title,
    release_date,
    LEAD(title) OVER (ORDER BY release_date) as next_film,
    LEAD(release_date) OVER (ORDER BY release_date) as next_release
FROM bluebox.film
WHERE release_date >= '2023-01-01'
ORDER BY release_date
LIMIT 5;
```

`LEAD` looks forward, `LAG` looks backward

---

[.footer: Slide 49 / 50]

## One More Technique: CTEs

Window functions often get combined with a **CTE** (Common Table Expression) to keep a multi-step query readable:

```sql
WITH customer_totals AS (
    SELECT customer_id, SUM(amount) as total_spent
    FROM bluebox.payment
    GROUP BY customer_id
)
SELECT 
    c.full_name,
    ct.total_spent,
    ROUND((SELECT AVG(total_spent) FROM customer_totals), 2) as avg_spent
FROM customer_totals ct
JOIN bluebox.customer c ON ct.customer_id = c.customer_id
WHERE ct.total_spent > (SELECT AVG(total_spent) FROM customer_totals)
ORDER BY ct.total_spent DESC LIMIT 5;
```

```
        full_name        | total_spent | avg_spent 
-------------------------+-------------+-----------
 Dr. Doris Abshire DDS   |      111.44 |     36.60
 Mr. Theodore Willms V   |      107.46 |     36.60
 Mrs. Ezequiel Orn I     |      107.46 |     36.60
```

The CTE `customer_totals` is referenced **3 times** - that's the power!

^ Judgment call: per the brief, CTEs are folded in here as a technique rather than given their own section/divider. Skip this slide first if time is short.

---

[.footer: Slide 50 / 50]

## Questions?

<br>
<br>

## Next: Postgres DBA Basics Nobody Told You
