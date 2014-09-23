DROP TABLE IF EXISTS tblEntityRegistrationAllowed;
CREATE TABLE `tblEntityRegistrationAllowed` (
  `intEntityRegistrationAllowedID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityID` int(11) NOT NULL,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) NOT NULL,
  `strPersonType` varchar(20) NOT NULL,
  `strSport` varchar(20) NOT NULL,
  intGender TINYINT DEFAULT 0,
  `strGender` VARCHAR(20) NULL COMMENT 'Change previous intGender to strgender to support importer requirement and transfer of reference criteria from tblentityRegistrationAllowed to tblEntity',
  `strPersonLevel` varchar(20) NOT NULL,
  `strRegistrationNature` varchar(20) NOT NULL,
  `strAgeLevel` varchar(20) NOT NULL,
  `intImportID` INT NULL COMMENT 'Tracking ID on which batch this record is included during import',
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intEntityRegistrationAllowedID`),
    KEY `index_intRealmID` (`intRealmID`),
    KEY `index_intSubRealmID` (`intSubRealmID`)
) DEFAULT CHARSET=utf8 COMMENT='This table shows which permuation and combination of players/coaches are available at each Entity';
