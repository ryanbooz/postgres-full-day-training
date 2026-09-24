# PGSummit NYC — Session Abstracts for Committee Submission

Draft copy for the program committee / schedule listing. Three separate 50-minute sessions,
presented as one series ("Beginning Postgres Workshop"). Each entry below has a title, a short
one-line teaser (for schedule grids or social posts), a full abstract (for the program page), and
the metadata fields most CFP forms ask for. Adjust length to whatever the actual submission form
allows — I don't know PGSummit's specific word-count limits, so trim from the full abstract if
needed rather than the teaser.

---

## Series overview (if the form wants one submission covering all three)

**Beginning Postgres Workshop**

*A three-part series for people who are newer to owning and operating PostgreSQL — not necessarily
newer to SQL. Across three fast-moving, demo-led sessions, we go from "comfortable running queries"
to "comfortable being the person on call for it": the SQL features and object types you'll actually
use, the operational basics nobody hands you on day one, and a diagnostic toolkit for when things
go sideways. Every session runs live queries against Bluebox, a real ~200k-row sample database, and
the environment stays up afterward so you can keep exploring. Come to one, or come to all three.*

Format: talk + live demo (no laptop setup required to attend). Level: assumes basic SQL comfort,
not Postgres operations experience.

---

## Session 1: Getting Comfortable with Postgres

**Tools, Users, Schemas, Objects, Arrays, JSONB & Window Functions**

**Teaser (one-line):**
> You know SQL. Here's the Postgres-specific stuff that makes you dangerous with it — from picking
> a client to querying JSONB like you mean it.

**Abstract:**

You can write a SELECT statement — but do you know your way around Postgres itself? This session
is a fast, live-demo tour built for people who know SQL but are newer to Postgres specifically.
We'll start with the practical stuff nobody explains well: psql vs. GUI clients, and how to pick
one. From there, a genuinely useful tour through roles and permissions, schemas, and Postgres's
data types — capped off with a live demo where we create a table, insert real rows, and query them
back. We'll close with three of Postgres's best SQL superpowers: arrays, JSONB, and window
functions, plus a look at how CTEs make all of it more readable. If you've been treating Postgres
like "just another SQL database," this is the session that shows you what you've been missing.

**Format:** Talk + live demo. **Duration:** 50 minutes. **Level:** Beginner-friendly (assumes SQL
familiarity). **Part:** 1 of 3.

**You'll walk away knowing:**
- How to choose and configure a Postgres client (psql or GUI) that fits how you work
- How roles, permissions, and schemas actually organize a real Postgres database
- How to model data with Postgres's richer types — including a live create-and-query demo
- How to use arrays, JSONB, and window functions to write fewer, smarter queries

---

## Session 2: Postgres DBA Basics Nobody Told You

**Teaser (one-line):**
> Backups, upgrades, replication, pooling, and vacuum — the operational knowledge that usually
> shows up for the first time during an incident. Let's get it into your head before that happens.

**Abstract:**

Nobody wakes up one day knowing how to safely back up a Postgres database, plan a version upgrade,
or explain why they need a connection pooler — it's usually learned the hard way, mid-incident.
This session gets you that knowledge ahead of time. We'll cover backup strategy (pg_dump vs.
pg_basebackup, and why WAL is the difference between a real backup and a false sense of security),
minor and major version upgrades and what actually changes, replication concepts for both
high-availability and selective data movement, why connection pooling matters even if you never
touch PgBouncer's config yourself, and VACUUM — what it does, why autovacuum usually has it handled,
and how to tell when it doesn't. We'll close with a tour of Postgres's extension ecosystem, from
the ones bundled in the box to PostGIS and pgvector. Live demos throughout, run against a real
sample database.

**Format:** Talk + live demo. **Duration:** 50 minutes. **Level:** Beginner-friendly (assumes SQL
familiarity, no prior DBA experience needed). **Part:** 2 of 3.

**You'll walk away knowing:**
- The difference between a backup and "a copy of your data directory" — and why it matters
- What actually happens during a minor vs. major version upgrade
- When you'd reach for streaming replication vs. logical replication
- Why almost every production Postgres setup uses a connection pooler
- What VACUUM does, and the handful of signs it needs your attention

---

## Session 3: When Postgres Misbehaves

**Locks, Monitoring & the Config That Matters**

**Teaser (one-line):**
> A slow query, a stuck transaction, and a config file with 300 settings you've never touched.
> Here's the diagnostic checklist — and how to actually read what Postgres's query planner is doing.

**Abstract:**

Something's wrong with your Postgres database — a query is stuck, the app is timing out, or it's
just "slow" and nobody can say why. This session is the diagnostic toolkit for exactly that moment.
We'll cover how to find and safely stop the queries and locks causing trouble, the timeout settings
that act as guardrails so it doesn't happen again, and the handful of metrics worth actually
watching. Then we'll spend real time on the single most useful skill for understanding *why* a
query is slow: reading Postgres's EXPLAIN output. You'll see how to read query costs and actual
execution times, recognize the difference between a sequential scan and an index scan, watch a
`CREATE INDEX` visibly change a query plan in real time, and walk away with a checklist of common
query anti-patterns and how to fix them. This is a mental model and a checklist, not deep tuning
mastery — everything here is meant to be useful the next time something misbehaves, whether or not
you've seen EXPLAIN output before.

**Format:** Talk + live demo. **Duration:** 50 minutes. **Level:** Beginner-friendly (assumes SQL
familiarity, no prior tuning experience needed). **Part:** 3 of 3.

**You'll walk away knowing:**
- How to find what's blocking what, and how to safely cancel or terminate it
- Which timeouts to set so runaway queries and stuck transactions can't linger
- The handful of Postgres metrics actually worth watching day to day
- How to read an EXPLAIN plan and tell a healthy query from a troubled one
- A handful of common query anti-patterns — and the fix for each

---

## Notes for whoever submits this

- These map directly to the final slide decks in this folder — `session-1-getting-comfortable.md`,
  `session-2-dba-basics.md`, `session-3-troubleshooting-tuning.md` — so the abstracts shouldn't
  promise anything the decks don't cover.
- Word counts above are generous (each abstract is ~150-180 words); trim from the abstract, not the
  teaser, if PGSummit's form has a hard limit.
- Speaker bio(s) aren't included here since that's not session content — add per whoever the
  committee confirms is presenting (see the still-open "presenting duties" question in
  `pgsummit-nyc-2026/README.md`).
- If the schedule tool wants all three sessions to visibly read as one series (rather than three
  unrelated talks), consider prefixing each title with "Beginning Postgres Workshop (Part 1 of 3):"
  etc. — left out of the titles above since that's more a schedule-display decision than a content
  one.
