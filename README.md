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

## Quick start with Docker

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

**Docker** — stop and remove the container:

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
       ROUND(ST_Distance_Sphere(s.location, d.location) / 1000) AS km
FROM routes r
JOIN airports s ON s.apid = r.src_apid
JOIN airports d ON d.apid = r.dst_apid
WHERE r.src_ap = 'HEL'
ORDER BY km DESC
LIMIT 10;

-- Airports within 100 km of Helsinki city centre.
-- Note: ST_Distance_Sphere on its own cannot use the spatial index —
-- EXPLAIN reports a full scan of all 7698 rows.
SELECT name, iata,
       ROUND(ST_Distance_Sphere(location, POINT(24.94, 60.17)) / 1000, 1) AS km
FROM airports
WHERE ST_Distance_Sphere(location, POINT(24.94, 60.17)) < 100000
ORDER BY km;

-- The same answer, using the index. MBRContains narrows the search to a
-- bounding box the index can serve; ST_Distance_Sphere then trims the
-- corners of that box down to a true radius.
SET @lon = 24.94, @lat = 60.17, @km = 100;
SET @dlat = @km / 111.0, @dlon = @km / (111.0 * COS(RADIANS(@lat)));

SELECT name, iata,
       ROUND(ST_Distance_Sphere(location, POINT(@lon, @lat)) / 1000, 1) AS km
FROM airports
WHERE MBRContains(ST_GeomFromText(CONCAT('POLYGON((',
        @lon-@dlon, ' ', @lat-@dlat, ',', @lon+@dlon, ' ', @lat-@dlat, ',',
        @lon+@dlon, ' ', @lat+@dlat, ',', @lon-@dlon, ' ', @lat+@dlat, ',',
        @lon-@dlon, ' ', @lat-@dlat, '))')), location)
  AND ST_Distance_Sphere(location, POINT(@lon, @lat)) < @km * 1000
ORDER BY km;
```

Run `EXPLAIN` on the last two to see the difference: `type: ALL, key: NULL`
against `type: range, key: location`.

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
