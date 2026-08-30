CREATE DATABASE IF NOT EXISTS flightdb2
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci;

USE flightdb2;

DROP TABLE IF EXISTS `routes`;
DROP TABLE IF EXISTS `airlines`;
DROP TABLE IF EXISTS `airports`;
DROP TABLE IF EXISTS `countries`;
DROP TABLE IF EXISTS `planes`;
DROP TABLE IF EXISTS `locales`;

CREATE TABLE `airlines` (
  `alid`         int      NOT NULL AUTO_INCREMENT,
  `name`         varchar(100) NOT NULL,
  `alias`        varchar(64)  DEFAULT NULL,
  `iata`         varchar(2)   DEFAULT NULL,
  `icao`         varchar(3)   DEFAULT NULL,
  `callsign`     varchar(64)  DEFAULT NULL,
  `country`      varchar(64)  DEFAULT NULL,
  `country_code` varchar(2)   DEFAULT NULL,
  `uid`          int          DEFAULT NULL,
  `mode`         char(1)      DEFAULT 'F',
  `active`       char(1)      DEFAULT 'N',
  `source`       varchar(32)  DEFAULT NULL,
  `frequency`    int          DEFAULT 0,
  PRIMARY KEY (`alid`),
  KEY `iata` (`iata`),
  KEY `icao` (`icao`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `airports` (
  `apid`         int      NOT NULL AUTO_INCREMENT,
  `name`         varchar(100) NOT NULL,
  `city`         varchar(64)  DEFAULT NULL,
  `country`      varchar(64)  DEFAULT NULL,
  `country_code` varchar(2),
  `iata`         varchar(3)   DEFAULT NULL,
  `icao`         varchar(4)   DEFAULT NULL,
  `x`            double       NOT NULL COMMENT 'longitude',
  `y`            double       NOT NULL COMMENT 'latitude',
  `location`     point        NOT NULL COMMENT 'POINT(longitude, latitude)',
  `elevation`    int              DEFAULT NULL,
  `uid`          int              DEFAULT NULL,
  `timezone`     float        DEFAULT NULL,
  `dst`          char(1)      DEFAULT NULL,
  `tz_id`        varchar(40)  DEFAULT NULL,
  `type`         varchar(16)  DEFAULT NULL,
  `source`       varchar(32)  DEFAULT NULL,
  PRIMARY KEY (`apid`),
  KEY `iata` (`iata`),
  SPATIAL INDEX `location` (`location`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `countries` (
  `dafif_code`   varchar(2)   NOT NULL,
  `name`         varchar(64)  NOT NULL,
  `iso_code`     varchar(2)   DEFAULT NULL,
  PRIMARY KEY (`dafif_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `planes` (
  `plid`         int      NOT NULL AUTO_INCREMENT,
  `name`         varchar(80),
  `iata`         varchar(4)   DEFAULT NULL,
  `icao`         varchar(8)   DEFAULT NULL,
  `abbr`         varchar(16)  DEFAULT NULL,
  `speed`        double       DEFAULT NULL,
  `public`       char(1)      DEFAULT 'N',
  `frequency`    int              DEFAULT 0,
  PRIMARY KEY (`plid`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `routes` (
  `rid`          int      NOT NULL AUTO_INCREMENT,
  `airline`      varchar(3)   DEFAULT NULL,
  `alid`         int              DEFAULT NULL,
  `src_ap`       varchar(4)   DEFAULT NULL,
  `src_apid`     int              DEFAULT NULL,
  `dst_ap`       varchar(4)   DEFAULT NULL,
  `dst_apid`     int              DEFAULT NULL,
  `codeshare`    char(1)      DEFAULT NULL,
  `stops`        tinyint unsigned NOT NULL DEFAULT 0,
  `equipment`    varchar(64)  DEFAULT NULL,
  `added`        varchar(1)   DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `alid` (`alid`, `src_apid`, `dst_apid`),
  KEY `src_apid` (`src_apid`),
  KEY `dst_apid` (`dst_apid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `locales` (
  `locale`       varchar(5)   NOT NULL,
  `name`         varchar(32)  NOT NULL,
  PRIMARY KEY (`locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT 'Done. Next: run sql/load-data.sql' AS '';
