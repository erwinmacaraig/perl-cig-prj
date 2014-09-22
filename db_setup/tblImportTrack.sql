CREATE TABLE `tblImportTrack` (
  `intImportID` INT NOT NULL AUTO_INCREMENT COMMENT 'This will be use to track all related record imported.',
  `strNotes` VARCHAR(250) NULL COMMENT 'Specific notes or justification of the said import',
  `tTimeStamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intImportID`));