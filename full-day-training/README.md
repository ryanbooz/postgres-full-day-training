# PostgreSQL Full Day Training

The complete curriculum: six hour-long sessions covering everything from your first `SELECT` to
reading query plans and tuning a production system. From absolute beginner to production-ready in
one day.

Presented at SCaLE 23x (2026) - Southern California Linux Expo.

> **Looking for the slides?** Use the PDFs in [`slides/`](slides/) — they're the finished,
> presentation-ready artifact, rebuilt each time this material is updated for a new event. The
> [`markdown/`](markdown/) folder is the editable Deckset source those PDFs are built from; it can
> change between presentations and isn't meant to be read as the final deck.

## Topics Covered

| Hour | Topics |
|------|--------|
| 1 | Setup, psql, schemas, data types, constraints |
| 2 | CRUD, JOINs, arrays, JSONB, window functions, CTEs |
| 3 | Backups, WAL, replication, connection pooling, VACUUM |
| 4 | System catalogs, logging, locks, monitoring |
| 5 | Memory config, shared_buffers, parallel queries |
| 6 | EXPLAIN, indexes, pg_stat_statements, query patterns |

## Get Set Up

From the repo root (see the [root README](../README.md) if you haven't cloned yet):

```bash
# 1. Start PostgreSQL
docker compose up -d

# 2. Install a psql client (choose one)
# Mac:
brew install libpq
# Windows: Use pgAdmin or install PostgreSQL from postgresql.org
# Linux:
apt install postgresql-client

# 3. Connect and create database
psql postgresql://postgres:training@localhost:5432/postgres -c "CREATE DATABASE bluebox;"
psql postgresql://postgres:training@localhost:5432/bluebox -c "CREATE EXTENSION postgis;"

# 4. Load Bluebox data
curl -LO https://raw.githubusercontent.com/ryanbooz/bluebox/main/bluebox_schema.sql
curl -LO https://raw.githubusercontent.com/ryanbooz/bluebox/main/bluebox_data.sql.gz
gunzip bluebox_data.sql.gz
psql postgresql://postgres:training@localhost:5432/bluebox -f bluebox_schema.sql
psql postgresql://postgres:training@localhost:5432/bluebox -f bluebox_data.sql

# 5. Verify
psql postgresql://postgres:training@localhost:5432/bluebox -c "SELECT COUNT(*) FROM bluebox.film;"
# Should return: 7836
```

Hour 1 includes this same setup walkthrough in slide form, with more detail and multiple psql
client options.

Using a GUI tool (pgAdmin, DBeaver, etc.) instead of psql, or can't install psql at all? See
[../TROUBLESHOOTING.md](../TROUBLESHOOTING.md) for both fallbacks.

Starting at Hour 3 or later? Some demos need the connection pooler and replication subscriber,
which the default `docker compose up -d` doesn't start:

```bash
docker compose --profile dba up -d
```

## Running the Training

### For Instructors

1. Open the PDFs in `slides/` to present, or the `markdown/hour-*.md` files in Deckset if you want
   to edit them
2. Ensure Docker is running with the Bluebox database loaded
3. Have a terminal ready for live demos

### For Self-Study

1. Follow Get Set Up above
2. Read through the PDFs in `slides/` in order
3. Run the SQL examples as you go (every example is also pulled out into `sql/`)

## Repository Structure

```
├── slides/                   # PDFs - the finished decks, read these
│   ├── hour-1-beginner.pdf
│   └── ...
├── markdown/                 # Deckset source the PDFs are built from - edit here, not slides/
│   ├── hour-1-beginner.md
│   └── ...
├── sql/                      # SQL examples extracted from each markdown/hour-*.md
├── scripts/                  # extract-sql.py, fix-slides.sh
└── add_slide_numbers.py      # Renumbers slide footers if slides are added/removed
```

Shared across every course in this repo, one level up: `docker-compose.yml`, `Dockerfile`,
`diagrams/`, `dependencies.md`, `TROUBLESHOOTING.md`.

## Markdown Format

Slides are written in Markdown for [Deckset](https://www.deckset.com/) (macOS) or another
markdown-to-slide program. They can also be viewed as plain Markdown or converted to other formats.

## Contributing

See [../CONTRIBUTING.md](../CONTRIBUTING.md).
