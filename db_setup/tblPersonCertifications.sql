DROP TABLE IF EXISTS `tblPersonCertifications`;
CREATE TABLE IF NOT EXISTS `tblPersonCertifications` (
  `intCertificationID` INT NOT NULL AUTO_INCREMENT,
  `intPersonID` INT NOT NULL,
  `intRealmID` INT NOT NULL,
  `intCertificationTypeID` INT NULL,
  `dtValidFrom` DATE NULL,
  `dtValidUntil` DATE NULL,
  `strDescription` VARCHAR(250) NULL,
  `strStatus` VARCHAR(45) NOT NULL DEFAULT 'ACTIVE',
  strPreviousStatus VARCHAR(45) DEFAULT '',
  PRIMARY KEY (`intCertificationID`)
) DEFAULT CHARSET=utf8;
