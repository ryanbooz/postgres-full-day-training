# Troubleshooting

## Loading Bluebox without a working psql or GUI tool

Bluebox's schema and data files are meant to be run with `psql -f` (they use `COPY`, not portable
`INSERT`s) — most GUI query tools (pgAdmin, DBeaver, etc.) can't execute them directly. If that
happens, load the files using the psql that's already running inside the container:

```bash
# Copy the downloaded files into the container
docker cp bluebox_schema.sql postgres-training:/tmp/
docker cp bluebox_data.sql postgres-training:/tmp/

# Load them from inside the container
docker exec -it postgres-training psql -U postgres -d bluebox -f /tmp/bluebox_schema.sql
docker exec -it postgres-training psql -U postgres -d bluebox -f /tmp/bluebox_data.sql
```

The container doesn't have the repo folder mounted, so it can't see files sitting on your host —
`docker cp` is what gets them in.

## Fixing docker issues

If you break your config and the `postgres-training` container will not start (for instance, setting `shared_preload_libraries = pgaudit` without the extension installed), you can do the following:

```
$ docker run --rm -it -v postgres-full-day-training_postgres_data:/repair alpine sh

$ vi /repair/18/docker/postgresql.auto.conf

# fix/save

$ docker compose --profile dba up -d
```


