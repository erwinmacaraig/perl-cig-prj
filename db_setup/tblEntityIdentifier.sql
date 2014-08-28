DROP TABLE IF EXISTS `tblEntityIdentifier`;
CREATE TABLE IF NOT EXISTS `tblEntityIdentifier` (
  `intIdentifierId` INT NOT NULL AUTO_INCREMENT,
  `intEntityID` INT NOT NULL,
  `intRealmID` INT NOT NULL,
  `intIdentifierTypeID` INT NOT NULL,
  `strIdentifier` VARCHAR(100) NOT NULL,
  `dtValidFrom` DATE NULL,
  `dtValidUntil` DATE NULL,
  `txtDescription` VARCHAR(250) NULL,
  PRIMARY KEY (`intIdentifierId`)
) DEFAULT CHARSET=utf8;