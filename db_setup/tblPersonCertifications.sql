DROP TABLE IF EXISTS `tblPersonCertifications`;
CREATE TABLE IF NOT EXISTS `tblPersonCertifications` (
  `intCertificationID` INT NOT NULL AUTO_INCREMENT,
  `intPersonID` INT NOT NULL,
  `intRealmID` INT NOT NULL,
  `intCertificationTypeID` INT NULL,
  `txtCertification` VARCHAR(100) NOT NULL,
  `intFileID` INT NULL,
  `dtValidFrom` DATE NULL,
  `dtValidUntil` DATE NULL,
  `strDescription` VARCHAR(250) NULL,
  `strStatus` VARCHAR(45) NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`intCertificationID`),
  UNIQUE INDEX `txtIdentifier_UNIQUE` (`txtCertification` ASC)
) DEFAULT CHARSET=utf8;