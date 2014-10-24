ALTER TABLE `tblEntity` 
DROP COLUMN `strGroundNature`,
DROP COLUMN `intLightCapacity`,
DROP COLUMN `intUncoveredStandingPlaces`,
DROP COLUMN `intCoveredStandingPlaces`,
DROP COLUMN `intUncoveredSeats`,
DROP COLUMN `intCoveredSeats`,
DROP COLUMN `intCapacity`,
ADD COLUMN `strSuburb` VARCHAR(100) NULL DEFAULT '' AFTER `strTown`,
ADD COLUMN `strState` VARCHAR(100) NULL DEFAULT NULL AFTER `strSuburb`;
