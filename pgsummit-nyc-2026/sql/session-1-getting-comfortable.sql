-- ============================================================
-- SQL examples from: session-1-getting-comfortable
-- ============================================================
-- -------------------------------------
-- Slide 7: Expanded Display: \x auto
-- -------------------------------------

\x auto   -- Let psql decide (recommended!)
\x on     -- Always expanded
\x off    -- Always horizontal (default)


-- -------------------------------------
-- Slide 8: More Useful psql Settings
-- -------------------------------------

\timing              -- Show query execution time
\conninfo            -- Show current connection info
\pset pager off      -- Turn off page-by-page scrolling


-- ---------------------------
-- Slide 11: Default Schema
-- ---------------------------

-- The default schema is 'public'
CREATE TABLE my_table (id int);

-- Same as:
CREATE TABLE public.my_table (id int);


-- -----------------------------
-- Slide 12: Creating Schemas
-- -----------------------------

-- Bluebox already has its schema, but you could create more:
CREATE SCHEMA reporting;

-- Then create tables in that schema
CREATE TABLE reporting.daily_stats (...);


-- -------------------------------
-- Slide 13: Schema Search Path
-- -------------------------------

-- View current search path
SHOW search_path;
-- Output: "$user", public

-- Set search path
SET search_path TO bluebox, public;

-- Now queries will look in bluebox first
SELECT * FROM film;  -- Same as bluebox.film


-- ---------------------------
-- Slide 14: Bluebox Schema
-- ---------------------------

SET search_path TO bluebox, public;
\dt


-- ---------------------------
-- Slide 15: Bluebox Tables
-- ---------------------------

\d bluebox.film


-- ---------------------------
-- Slide 17: Postgres Roles
-- ---------------------------

-- Create a user (role with login)
CREATE ROLE app_user WITH LOGIN PASSWORD 'secure_password';

-- Create a group (role without login)
CREATE ROLE readonly;


-- ----------------------------
-- Slide 18: Role Attributes
-- ----------------------------

CREATE ROLE app_user WITH 
  LOGIN 
  PASSWORD 'secure_password'
  CREATEDB 
  CREATEROLE;


-- --------------------------------
-- Slide 19: Granting Privileges
-- --------------------------------

-- Grant connection to database
GRANT CONNECT ON DATABASE bluebox TO app_user;

-- Grant schema usage
GRANT USAGE ON SCHEMA bluebox TO app_user;

-- Grant table privileges
GRANT SELECT ON ALL TABLES IN SCHEMA bluebox TO app_user;

-- Grant specific privileges
GRANT SELECT, INSERT, UPDATE ON bluebox.rental TO app_user;


-- ------------------------------------------
-- Slide 20: Manage Privileges with Groups
-- ------------------------------------------

-- Create a group role for data analytics team
CREATE ROLE data_analytics NOLOGIN;

-- Grant read access on Bluebox to the group
GRANT CONNECT ON DATABASE bluebox TO data_analytics;
GRANT USAGE ON SCHEMA bluebox TO data_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA bluebox TO data_analytics;


-- ----------------------------------------
-- Slide 21: Grant Users Role Membership
-- ----------------------------------------

-- Create a user for an analyst
CREATE ROLE maria LOGIN;
\password maria

-- Add maria to the data_analytics group
GRANT data_analytics TO maria;

-- Maria now inherits all permissions from data_analytics!


-- ----------------------------------
-- Slide 22: View Role Memberships
-- ----------------------------------

\du


-- -----------------------------------
-- Slide 23: ALTER User Search Path
-- -----------------------------------

-- Set search path
ALTER USER maria SET search_path TO bluebox, public;

-- From next login, queries will look in bluebox first
SELECT * FROM film;  -- Same as bluebox.film


-- -------------------------------------
-- Slide 27: ⏰ Time: Use TIMESTAMPTZ!
-- -------------------------------------

-- TIMESTAMP: No timezone info (dangerous!)
CREATE TABLE events (event_time TIMESTAMP);

-- TIMESTAMPTZ: Stores in UTC, converts on display ✓
CREATE TABLE events (event_time TIMESTAMPTZ);

-- What time is it?
SELECT NOW();  -- 2026-01-16 10:30:00-08


-- --------------------------------------
-- Slide 28: 💰 Use NUMERIC, Not MONEY!
-- --------------------------------------

-- DON'T use the MONEY type
price MONEY  -- ❌ Locale-dependent, rounding issues

-- DO use NUMERIC for currency
price NUMERIC(10,2)  -- ✓ Exact precision, no surprises

SELECT amount FROM bluebox.payment LIMIT 3;


-- --------------------------------------
-- Slide 29: 🎯 Custom Data Types: ENUM
-- --------------------------------------

CREATE TYPE mpaa_rating AS ENUM (
    'G', 'PG', 'PG-13', 'R', 'NC-17', 'NR'
);

-- Used in the film table
SELECT title, rating FROM bluebox.film 
WHERE rating = 'PG-13' LIMIT 3;


-- -----------------------------
-- Slide 31: Creating a Table
-- -----------------------------

CREATE TABLE bluebox.customer_review (
    review_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES bluebox.customer(customer_id),
    film_id BIGINT REFERENCES bluebox.film(film_id),
    rating SMALLINT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- -----------------------------------------------
-- Slide 32: 🔧 Demo: Add Yourself as a Customer
-- -----------------------------------------------

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


-- -----------------------------------------
-- Slide 33: 🔧 Demo: Find Films to Review
-- -----------------------------------------

-- Find some popular films to review
SELECT film_id, title FROM bluebox.film 
WHERE title IN ('The Dark Knight', 'Inception', 
                'Interstellar', 'Dune: Part Two');


-- ----------------------------------------
-- Slide 34: 🔧 Demo: Insert Your Reviews
-- ----------------------------------------

-- Use YOUR customer_id from the previous step!
INSERT INTO bluebox.customer_review 
    (customer_id, film_id, rating, review_text)
VALUES 
    (205026, 155, 5, 'Heath Ledger was incredible!'),
    (205026, 27205, 5, 'Mind-bending! Had to watch twice'),
    (205026, 693134, 5, 'Even better than the first Dune!');


-- ---------------------------
-- Slide 35: Joining Tables
-- ---------------------------

SELECT f.title, p.name as actor
FROM bluebox.film f
INNER JOIN bluebox.film_cast fc ON f.film_id = fc.film_id
INNER JOIN bluebox.person p ON fc.person_id = p.person_id
WHERE f.title = 'The Dark Knight'
LIMIT 3;


-- ------------------------------------------
-- Slide 36: 🔧 Demo: Querying Your Reviews
-- ------------------------------------------

-- See your reviews with a JOIN
SELECT c.full_name, f.title, r.rating, 
       LEFT(r.review_text, 30) as review
FROM bluebox.customer_review r
JOIN bluebox.customer c ON r.customer_id = c.customer_id
JOIN bluebox.film f ON r.film_id = f.film_id
ORDER BY r.created_at DESC;


-- ---------------------------------
-- Slide 38: Arrays in PostgreSQL
-- ---------------------------------

SELECT film_id, title, genre_ids 
FROM bluebox.film 
WHERE title = 'The Dark Knight';

-- What do these IDs mean? Check the film_genre table
SELECT genre_id, name FROM bluebox.film_genre 
WHERE genre_id IN (18, 28, 80, 53);


-- -------------------------------
-- Slide 39: Adding to an Array
-- -------------------------------

BEGIN;  -- demo only: we'll roll this back

-- Add a genre to a film's array
UPDATE bluebox.film
SET genre_ids = genre_ids || ARRAY[9648]  -- Add Mystery
WHERE film_id = 155
RETURNING genre_ids;
-- {18,28,80,53,9648}

-- Alternative: array_append(genre_ids, 9648)

ROLLBACK;  -- keep The Dark Knight's genres unchanged


-- ----------------------------
-- Slide 41: Querying Arrays
-- ----------------------------

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


-- -------------------------------
-- Slide 43: Working with JSONB
-- -------------------------------

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

-- Different row, completely different structure - that's OK!
INSERT INTO movie_metadata (movie_id, data)
VALUES (2, '{
    "streaming": ["Netflix", "Hulu"],
    "runtime_minutes": 148,
    "has_sequel": true
}');


-- ---------------------------
-- Slide 45: Querying JSONB
-- ---------------------------

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


-- ---------------------------
-- Slide 48: Running Totals
-- ---------------------------

SELECT 
    payment_date::date,
    amount,
    SUM(amount) OVER (
        ORDER BY payment_date
    ) as running_total
FROM bluebox.payment
WHERE customer_id = 53853
ORDER BY payment_date;


-- ------------------------------------------
-- Slide 49: LAG - Compare to Previous Row
-- ------------------------------------------

SELECT 
    payment_date::date,
    amount,
    LAG(amount) OVER (ORDER BY payment_date) as prev_amount,
    amount - LAG(amount) OVER (ORDER BY payment_date) as difference
FROM bluebox.payment
WHERE customer_id = 53853
ORDER BY payment_date;


-- -----------------------------------
-- Slide 50: RANK with PARTITION BY
-- -----------------------------------

SELECT title, rating, vote_average,
       RANK() OVER (PARTITION BY rating
                    ORDER BY vote_average DESC) AS rank_in_rating
FROM bluebox.film
WHERE rating IN ('G', 'PG') AND vote_count > 18000
ORDER BY rating, rank_in_rating;


-- -------------------------------------
-- Slide 51: One More Technique: CTEs
-- -------------------------------------

WITH ranked AS (
    SELECT title, rating, vote_average,
           RANK() OVER (PARTITION BY rating
                        ORDER BY vote_average DESC) AS rnk
    FROM bluebox.film
    WHERE vote_count > 5000
)
SELECT rating, rnk, title, vote_average
FROM ranked
WHERE rnk <= 2 AND rating IN ('G', 'PG', 'PG-13')
ORDER BY rating, rnk;
