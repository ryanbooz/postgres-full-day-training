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

[.footer: Slide 1 / 14]

## Get Set Up: PostgreSQL + Bluebox
### Docker, psql, and the Sample Database
<br>
<br>
## Setup Guide — Beginning Postgres Workshop
### PGSummit NYC

^ This is NOT a live session — it's a standalone PDF/deck to send out ahead of time and to point
people to if they arrive early (breakfast/opening/keynote) or want to redo setup after the
conference. Content is pulled from hour-1-beginner.md's installation section only. See
pgsummit-nyc-2026/README.md.

---

[.footer: Slide 2 / 14]

## Training Materials

[.column]

All slides, exercises, and Docker setup:

### github.com/elizabeth-christensen/postgres-full-day-training

Sample database:

### github.com/ryanbooz/bluebox


[.column]

postgres.app for macs will create a psql connection

---

[.footer: Slide 3 / 14]

## Let's Get Connected!

## Setup Overview

1. Start PostgreSQL (Docker)
2. Install a psql client
3. Connect and load sample data
4. Verify everything works

~10-15 minutes

---

[.footer: Slide 4 / 14]

## Prerequisites

You need **Docker Desktop** installed and running

- **Mac/Windows**: docker.com/products/docker-desktop
- **Linux**: Docker Engine + Docker Compose

Verify it's working:

```bash
docker --version
docker compose version
```

---

[.footer: Slide 5 / 14]

## Step 1: Clone the Repository

```bash
## Clone the training repo
git clone https://github.com/Snowflake-Labs/postgres-full-day-training.git

## Navigate into the folder
cd postgres-full-day-training
```

Or download as ZIP from GitHub if you don't have git.

---

[.footer: Slide 6 / 14]

## Step 2: Start PostgreSQL

```bash
## Start PostgreSQL container
docker compose up -d

## Verify it's running
docker ps
```

You should see `postgres-training` running on port 5432.

```
CONTAINER ID   IMAGE                    STATUS         PORTS
abc123...      postgis/postgis:18-3.6   Up 10 seconds  0.0.0.0:5432->5432/tcp
```

---

[.footer: Slide 7 / 14]

## Step 3: Install a psql Client

You need a way to connect to PostgreSQL. Choose one:

[.column]

Mac
- `brew install libpq` (client only)
- `brew install postgresql@18`
- Postgres.app (includes psql)

Windows
- PostgreSQL installer (postgresql.org)
- pgAdmin (standalone)

[.column]

Linux
- `apt install postgresql-client`
- `yum install postgresql`

Cross-Platform GUIs
- pgAdmin
- DBeaver
- TablePlus
- Azure Data Studio
- Beekeeper Studio

---

[.footer: Slide 8 / 14]

## Mac: Homebrew (Recommended)

```bash
## Install just the client tools (no server)
brew install libpq

## Add to your PATH
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

## Verify
psql --version
```

Alternative: Install Postgres.app and use its bundled psql.

---

[.footer: Slide 9 / 14]

## Windows / GUI Users

**pgAdmin** is a great option:

1. Download from pgadmin.org
2. Add a new server connection:
   - Host: `localhost`
   - Port: `5432`
   - Username: `postgres`
   - Password: `training`

pgAdmin includes a Query Tool that works like psql.

---

[.footer: Slide 10 / 14]

## Step 4: Connect to PostgreSQL

```bash
## Connect using psql
psql postgresql://postgres:training@localhost:5432/postgres
```

You should see:

```
psql (18.x)
Type "help" for help.

postgres=#
```

You're connected! 🎉

---

[.footer: Slide 11 / 14]

## Step 5: Create Database and Load Bluebox

From psql, create the database:

```sql
CREATE DATABASE bluebox;
\c bluebox
CREATE EXTENSION postgis;
```

Then exit psql (`\q`) and load the data:

```bash
## Download Bluebox files
curl -LO https://raw.githubusercontent.com/ryanbooz/bluebox/main/bluebox_schema.sql
curl -LO https://raw.githubusercontent.com/ryanbooz/bluebox/main/bluebox_data.sql.gz
gunzip bluebox_data.sql.gz

## Load schema and data
psql postgresql://postgres:training@localhost:5432/bluebox -f bluebox_schema.sql
psql postgresql://postgres:training@localhost:5432/bluebox -f bluebox_data.sql
```

---

[.footer: Slide 12 / 14]

## Step 6: Verify Your Setup

Connect to the bluebox database:

```bash
psql postgresql://postgres:training@localhost:5432/bluebox
```

Run a test query:

```sql
SELECT COUNT(*) FROM bluebox.film;
```

```
 count 
-------
  7836
```

If you see 7836 films, you're all set! ✅

---

[.footer: Slide 13 / 14]

## Troubleshooting: Last Resort

If you can't install psql locally, use Docker:

```bash
## Connect via docker exec
docker exec -it postgres-training psql -U postgres -d bluebox
```

This works but isn't ideal for learning psql workflows.

**Common issues:**
- Docker not running → Start Docker Desktop
- Port conflict → Check if another Postgres is using 5432
- Permission denied → Run Docker Desktop as admin (Windows)

---

[.footer: Slide 14 / 14]

## You're Ready!

Keep this environment around — it stays useful for all three workshop sessions, and afterward for
you to keep exploring on your own.

**See you at the workshop!**
