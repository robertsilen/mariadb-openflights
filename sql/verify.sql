-- Verifies a loaded flightdb2 against the expected row counts.
-- Exits non-zero if any table does not match, so it can be used in CI:
--
--     mariadb < sql/verify.sql
--
-- To check the data files themselves, see data/SHA256SUMS.

USE flightdb2;

CREATE OR REPLACE TEMPORARY TABLE _expected (tbl VARCHAR(32) PRIMARY KEY, n INT NOT NULL);
INSERT INTO _expected VALUES
  ('airlines',   6162),
  ('airports',   7698),
  ('countries',   261),
  ('locales',      14),
  ('planes',      246),
  ('routes',    67663);

CREATE OR REPLACE TEMPORARY TABLE _actual (tbl VARCHAR(32) PRIMARY KEY, n INT NOT NULL);
INSERT INTO _actual
  SELECT 'airlines',  COUNT(*) FROM airlines
  UNION ALL SELECT 'airports',  COUNT(*) FROM airports
  UNION ALL SELECT 'countries', COUNT(*) FROM countries
  UNION ALL SELECT 'locales',   COUNT(*) FROM locales
  UNION ALL SELECT 'planes',    COUNT(*) FROM planes
  UNION ALL SELECT 'routes',    COUNT(*) FROM routes;

SELECT e.tbl AS `table`, e.n AS expected, a.n AS actual,
       IF(e.n = a.n, 'ok', 'MISMATCH') AS result
FROM _expected e JOIN _actual a USING (tbl)
ORDER BY e.tbl;

DELIMITER //
BEGIN NOT ATOMIC
  IF (SELECT COUNT(*) FROM _expected e JOIN _actual a USING (tbl) WHERE e.n <> a.n) > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Row count verification FAILED';
  END IF;
END//
DELIMITER ;

DROP TEMPORARY TABLE _expected, _actual;

SELECT 'All row counts match.' AS '';
