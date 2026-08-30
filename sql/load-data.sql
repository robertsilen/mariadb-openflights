USE flightdb2;

SELECT 'Importing airlines...' AS '';
LOAD DATA LOCAL INFILE 'data/airlines.dat'
REPLACE INTO TABLE airlines
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(alid, name, alias, iata, icao, callsign, country, active);

SELECT 'Importing airports...' AS '';
LOAD DATA LOCAL INFILE 'data/airports.dat'
REPLACE INTO TABLE airports
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(apid, name, city, country, iata, icao, @y, @x, elevation, timezone, dst, tz_id, type, source)
SET y = @y,
    x = @x,
    location = POINT(@x, @y);

SELECT 'Importing routes...' AS '';
LOAD DATA LOCAL INFILE 'data/routes.dat'
REPLACE INTO TABLE routes
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(airline, alid, src_ap, src_apid, dst_ap, dst_apid, codeshare, stops, equipment);

SELECT 'Importing countries...' AS '';
LOAD DATA LOCAL INFILE 'data/countries.dat'
REPLACE INTO TABLE countries
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(name, iso_code, dafif_code);

SELECT 'Importing planes...' AS '';
LOAD DATA LOCAL INFILE 'data/planes.dat'
REPLACE INTO TABLE planes
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(name, iata, icao);

SELECT 'Importing locales...' AS '';
LOAD DATA LOCAL INFILE 'data/locales.dat'
REPLACE INTO TABLE locales
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(locale, name);

-- A route may name an airport that is not in airports.dat. The two files are
-- snapshots of the same upstream database taken at different times, so routes
-- references airports that were added to, or removed from, the airport list
-- afterwards. Null the dangling id: src_ap/dst_ap keep the IATA code, so the
-- route still says where it went, and the foreign keys below can be enforced.
SELECT 'Resolving routes that reference unknown airports...' AS '';
UPDATE routes r LEFT JOIN airports a ON a.apid = r.src_apid
   SET r.src_apid = NULL
 WHERE r.src_apid IS NOT NULL AND a.apid IS NULL;
UPDATE routes r LEFT JOIN airports a ON a.apid = r.dst_apid
   SET r.dst_apid = NULL
 WHERE r.dst_apid IS NOT NULL AND a.apid IS NULL;

SELECT 'Adding foreign keys...' AS '';
ALTER TABLE routes
  ADD CONSTRAINT `fk_routes_airline` FOREIGN KEY (`alid`)     REFERENCES `airlines` (`alid`),
  ADD CONSTRAINT `fk_routes_src`     FOREIGN KEY (`src_apid`) REFERENCES `airports` (`apid`),
  ADD CONSTRAINT `fk_routes_dst`     FOREIGN KEY (`dst_apid`) REFERENCES `airports` (`apid`);

SELECT 'Done.' AS '';
