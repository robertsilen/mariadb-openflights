# OpenFlights dataset for MariaDB

A ready-to-import dataset of airports, airlines, routes, countries, and planes — sourced from [OpenFlights](https://github.com/jpatokal/openflights) and packaged for MariaDB.

## Tables

| Table | Description |
|-------|-------------|
| `airports` | ~7700 airports worldwide with IATA/ICAO codes, coordinates, timezone |
| `airlines` | ~6000 airlines with IATA/ICAO codes, country |
| `routes` | ~67000 routes between airports |
| `countries` | Country codes (ISO and DAFIF) |
| `planes` | Aircraft types with IATA/ICAO codes |
| `locales` | Supported locale codes and display names |

## Quick start with local MariaDB

```sh
git clone https://github.com/mariadb/openflights
cd openflights

sudo mariadb < sql/create.sql
sudo mariadb --local-infile=1 < sql/load-data.sql

# Open the MariaDB client with the flightdb2 database selected
sudo mariadb flightdb2
```

This works on a stock distribution package install, where the MariaDB `root` account authenticates through the unix socket, so `sudo` is used and no password is asked for. If you have set a password for `root`, use `mariadb -u root -p` instead.

## Quick start with Docker Compose

One command, and the schema and data are already loaded when it returns:

```sh
git clone https://github.com/mariadb/openflights
cd openflights

docker compose up --wait
docker compose exec mariadb mariadb -u root -popenflights flightdb2
```

### What you get

A MariaDB server with the `flightdb2` database populated and ready to query:

| Table | Rows |
|-------|------|
| `airports` | 7 698 |
| `airlines` | 6 162 |
| `routes` | 67 663 |
| `countries` | 261 |
| `planes` | 246 |
| `locales` | 14 |

Roughly six seconds from an empty volume to a populated database, image
download excluded. Nothing is installed on the host — removing the container
and its volume removes every trace.

To connect from a GUI client (DBeaver, TablePlus, DataGrip) or any driver:

| | |
|---|---|
| Host / port | `127.0.0.1` / `3306` |
| User / password | `root` / `openflights` |
| Database | `flightdb2` |

The password is set in `docker-compose.yml`. This is a local development
container, so it is deliberately not a secret.

### How it works

`docker-compose.yml` mounts `data/` and `sql/` read-only into the container
and puts `docker/init.sh` in the MariaDB image's init directory. On the first
start, the entrypoint initialises the server and then runs that script, which
applies `sql/create.sql` and `sql/load-data.sql` — the same two files used for
a local install. The server only begins accepting outside connections once
that has finished, which is why `--wait` returns a database that is already
populated rather than one that is still loading.

Because the SQL and data are mounted from your working copy rather than
copied into an image, editing them and recreating the volume is enough to see
the change:

```sh
docker compose down -v && docker compose up --wait
```

Otherwise the data is loaded once, when the volume is first created, and
restarting keeps it.

### Options

```sh
MARIADB_VERSION=11.4 docker compose up --wait   # test another server version
MARIADB_PORT=3307    docker compose up --wait   # if 3306 is already in use
```

`MARIADB_VERSION` accepts any tag of the official image, which makes "does
this feature exist in 10.11?" a five-second experiment. The default is
`lts`.

> **If you already run MariaDB or MySQL on port 3306**, set `MARIADB_PORT`.
> Otherwise a host connection to `127.0.0.1:3306` may silently reach your
> existing server instead of the container, with no error to tell you.
> `docker compose exec` is unaffected — it always reaches the container.

## Quick start with Docker (without Compose)

```sh
git clone https://github.com/mariadb/openflights
cd openflights

# Start MariaDB
docker run -d \
  --name openflights-mariadb \
  -e MARIADB_ROOT_PASSWORD=rootpw123 \
  -p 3306:3306 \
  -v $(pwd):/openflights \
  mariadb:11.7

# Create database and tables
docker exec -i openflights-mariadb \
  mariadb -u root -prootpw123 < sql/create.sql

# Load data (run from repo root so data/ paths resolve)
docker exec -i openflights-mariadb \
  bash -c "cd /openflights && mariadb --local-infile=1 -u root -prootpw123 < sql/load-data.sql"

# Open the MariaDB client with the flightdb2 database selected
docker exec -it openflights-mariadb mariadb -u root -prootpw123 flightdb2
```

## Cleanup

**Local MariaDB** — drop the database:

```sql
DROP DATABASE flightdb2;
```

**Docker Compose** — stop the container and remove its data:

```sh
docker compose down -v
```

**Docker without Compose** — stop and remove the container:

```sh
docker rm -f openflights-mariadb
```

## Example queries

```sql
USE flightdb2;

-- List the tables
SHOW TABLES;

-- Columns of a single table
DESCRIBE airports;

-- Airports in Finland
SELECT name, city, iata, icao FROM airports WHERE country = 'Finland';

-- Airlines flying from a given country
SELECT name, iata, icao, active FROM airlines WHERE country = 'Finland';

-- All routes out of Helsinki (HEL)
SELECT r.airline, a.name AS destination, r.dst_ap
FROM routes r
JOIN airports a ON a.apid = r.dst_apid
WHERE r.src_ap = 'HEL'
ORDER BY a.name;

-- Airlines with the most routes
SELECT a.name AS airline, a.iata, COUNT(*) AS routes
FROM routes r
JOIN airlines a ON a.alid = r.alid
GROUP BY r.alid
ORDER BY routes DESC
LIMIT 10;

-- Top 10 airports by number of departing routes
SELECT a.name, a.iata, COUNT(*) AS departures
FROM routes r
JOIN airports a ON a.apid = r.src_apid
GROUP BY r.src_apid
ORDER BY departures DESC
LIMIT 10;

-- Countries with the most airports
SELECT country, COUNT(*) AS cnt
FROM airports
GROUP BY country
ORDER BY cnt DESC
LIMIT 10;

-- Longest routes out of Helsinki, by great-circle distance in km
SELECT DISTINCT r.dst_ap, d.name AS destination,
       ROUND(ST_Distance_Sphere(POINT(s.x, s.y), POINT(d.x, d.y)) / 1000) AS km
FROM routes r
JOIN airports s ON s.apid = r.src_apid
JOIN airports d ON d.apid = r.dst_apid
WHERE r.src_ap = 'HEL'
ORDER BY km DESC
LIMIT 10;
```

## Data files

Raw CSV data is in `data/`. The files have no header row.

| File | Columns (in order) |
|------|--------------------|
| `airlines.dat` | alid, name, alias, iata, icao, callsign, country, active |
| `airports.dat` | apid, name, city, country, iata, icao, lat, lon, elevation, timezone, dst, tz_id, type, source |
| `routes.dat` | airline, alid, src_ap, src_apid, dst_ap, dst_apid, codeshare, stops, equipment |
| `countries.dat` | name, iso_code, dafif_code |
| `planes.dat` | name, iata, icao |
| `locales.dat` | locale, name |

See the [OpenFlights data documentation](https://openflights.org/data.php) for full field descriptions.

## License

Data is made available under the [Open Database License](https://opendatacommons.org/licenses/odbl/1-0/). See [LICENSE](LICENSE).
