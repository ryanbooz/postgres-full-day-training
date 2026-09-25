# Beginning Postgres Workshop — PGSummit NYC 2026

A three-part series for people who are newer to *owning and operating* PostgreSQL — not necessarily
newer to SQL. Across three fast-moving, demo-led sessions, we go from "comfortable running queries"
to "comfortable being the person on call for it": the SQL features and object types you'll actually
use, the operational basics nobody hands you on day one, and a diagnostic toolkit for when things
go sideways.

Every session runs live queries against **Bluebox**, a real ~200k-row sample movie database, and
the environment stays up afterward so you can keep exploring on your own.

**Format:** talk + live demo. No laptop setup is required to attend — sit back and watch the demos.
**Level:** assumes basic SQL comfort, not Postgres operations experience.

> **Looking for the slides?** Use the PDFs in [`slides/`](slides/) — they're the finished,
> presentation-ready decks, rebuilt for this conference. The [`markdown/`](markdown/) folder is the
> editable Deckset source those PDFs are built from; it can still change before the sessions and
> isn't meant to be read as the final deck.

## Get set up (optional, but recommended)

You don't need anything installed to follow along in the room. But if you'd like to run the demo
queries yourself — during the sessions, at breakfast beforehand, or any time after the
conference — follow **[slides/session-0-setup.pdf](slides/session-0-setup.pdf)**. It walks through
installing Docker, a psql client, and loading Bluebox (~10-15 minutes). We're also happy to help in
person before the sessions start.

## Sessions

### 1. Getting Comfortable with Postgres
*Tools, Users, Schemas, Objects, Arrays, JSONB & Window Functions*

You know SQL — here's the Postgres-specific stuff that makes you dangerous with it. A quick tour
of picking a client (psql vs. GUI), then roles/permissions, schemas, and Postgres's richer data
types, capped with a live demo: create a table, insert real rows, and query them back with a join.
We close with three of Postgres's best SQL superpowers — arrays, JSONB, and window functions — plus
how CTEs make it all more readable.

→ [slides/session-1-getting-comfortable.pdf](slides/session-1-getting-comfortable.pdf)

### 2. Postgres DBA Basics Nobody Told You
*Backups, WAL, Upgrades, Replication, Pooling & VACUUM*

The operational knowledge that usually shows up for the first time during an incident — backup
strategy (and why WAL is the difference between a real backup and a false sense of security),
minor and major version upgrades, replication concepts for both HA and selective data movement,
why almost every production setup uses a connection pooler, VACUUM, and a tour of the extension
ecosystem from contrib to PostGIS and pgvector.

→ [slides/session-2-dba-basics.pdf](slides/session-2-dba-basics.pdf)

### 3. When Postgres Misbehaves
*Locks, Monitoring, Key Config & Reading Query Plans*

A slow query, a stuck transaction, a config file with 300 settings you've never touched — this is
the diagnostic toolkit for that moment. Finding and safely stopping bad queries and locks, the
timeouts that act as guardrails, the handful of metrics worth watching, and real time spent on the
single most useful skill for understanding *why* a query is slow: reading `EXPLAIN` output. Closes
with a checklist of common query anti-patterns and how to fix them.

→ [slides/session-3-troubleshooting-tuning.pdf](slides/session-3-troubleshooting-tuning.pdf)

## Resources

- Training repo (this repo): [github.com/ryanbooz/postgres-full-day-training](https://github.com/ryanbooz/postgres-full-day-training)
- Sample database: [github.com/ryanbooz/bluebox](https://github.com/ryanbooz/bluebox)
- Ready-made Docker Image: [github.com/ryanbooz/bluebox-docker](https://github.com/ryanbooz/bluebox-docker)

