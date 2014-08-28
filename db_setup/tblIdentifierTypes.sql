DROP TABLE IF EXISTS `tblIdentifierTypes`;
CREATE TABLE IF NOT EXISTS `tblIdentifierTypes` (
  `intIdentifierTypeID` INT NOT NULL AUTO_INCREMENT,
  `intRealmID` INT NULL,
  `strIdentifierName` VARCHAR(45) NULL,
  `tTimeStamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intStatus` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`intIdentifierTypeID`)
) DEFAULT CHARSET=utf8;