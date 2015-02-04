DROP TABLE IF EXISTS tblEntityFields;

CREATE TABLE `tblEntityFields` (
    `intEntityFieldID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `intEntityID` INT NOT NULL COMMENT 'Entity (Venue/Facility) this Field is linked to',
    `intFieldOrderNumber` INT NULL,
    `strName` VARCHAR(200) NOT NULL COMMENT 'Name of the field.',
    `strDiscipline` VARCHAR(100) NOT NULL COMMENT 'FOOTBALL, FUTSAL etc (code level enumeration). The discipline/sport which is being played on the stadium.',
    `intCapacity` INT NOT NULL COMMENT 'The maximum number of people allowed as audience/spectators.',
    `strGroundNature` VARCHAR(100) NOT NULL COMMENT 'The type of ground in the stadium, e.g. natural grass or artificial turf.',
    `dblLength` DOUBLE NULL COMMENT 'The length of a field defined in meters (m).',
    `dblWidth` DOUBLE NULL COMMENT 'The length of a field defined in meters (m).',
    `dblLat` DOUBLE NULL,
    `dblLong` DOUBLE NULL,
    `intCoveredSeats` INT NULL,
    `intUncoveredSeats` INT NULL,
    `intCoveredStandingPlaces` INT NULL,
    `intUncoveredStandingPlaces` INT NULL,
    `intLightCapacity` INT NULL,
    `strStatus` VARCHAR(20) NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE|DELETED - flag value whether to display field or not',
    `intImportId` INT NULL,
    PRIMARY KEY (`intEntityFieldID`))
COMMENT = 'FacilityType as per FIFA FDS (additional fields moved from tblEntity)';
