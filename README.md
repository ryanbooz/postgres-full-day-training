# PostgreSQL Training

An open-source PostgreSQL curriculum, presented at various Postgres and Linux conferences. Every
course runs live queries against [Bluebox](https://github.com/ryanbooz/bluebox), a real sample
movie database with TMDB data and PostGIS geography, using the same Docker setup across every
course in this repo.

## Find Your Course

| Course | What it is |
|--------|------------|
| [`full-day-training/`](full-day-training/) | The complete 6-hour curriculum — absolute beginner through query tuning. Presented at SCaLE 23x (2026). |
| [`pgsummit-nyc-2026/`](pgsummit-nyc-2026/) | A trimmed, 3-session "Beginning Postgres Workshop." Presented at PGSummit NYC 2026. |

Each course folder has its own README with the topics it covers, a setup guide, and links to its
slides. **Start there, not here** — this page only covers what's shared across all of them.

## Prerequisites

**Software:** Docker Desktop is the only thing you need installed.

- **Mac/Windows**: [docker.com/products/docker-desktop](https://docker.com/products/docker-desktop)
- **Linux**: Docker Engine + Docker Compose

```bash
# Verify Docker is installed
docker --version
docker compose version
```

**Background:** Basic SQL familiarity is helpful but not required.

## Shared Infrastructure

Every course clones the same repo and stands up the same environment:

```bash
git clone https://github.com/ryanbooz/postgres-full-day-training.git
cd postgres-full-day-training
docker compose up -d
```

- `docker-compose.yml` / `Dockerfile` - the Postgres + PostGIS + extensions environment every
  course uses. Some later demos need the connection pooler and replication subscriber, which
  aren't in the default `up -d` - start with `docker compose --profile dba up -d` instead (each
  course's README says when).
- `diagrams/` - images shared across course folders.
- [`dependencies.md`](dependencies.md) - every piece of software and extension used, with licenses.
- [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) - common Docker/setup issues, including loading
  Bluebox without a working psql or GUI tool.

## PostgreSQL Version

The shared environment targets **PostgreSQL 18** but is compatible with PostgreSQL 14+. Some
features covered in the material (like `RETURNING OLD/NEW` and `WITHOUT OVERLAPS`) require
PostgreSQL 18.

## Markdown Format

Slides are written in Markdown for [Deckset](https://www.deckset.com/) (macOS) or another
markdown-to-slide program. They can also be viewed as plain Markdown or converted to other formats.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Acknowledgments

- [Bluebox](https://github.com/ryanbooz/bluebox) sample database by Ryan Booz
- The PostgreSQL community
- [TMDB](https://www.themoviedb.org/) for movie data used in Bluebox

---

**Questions?** Open an issue or reach out to the maintainers.
