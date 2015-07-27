DROP TABLE IF EXISTS `tblCertificationTypes`;
CREATE TABLE IF NOT EXISTS `tblCertificationTypes` (
  `intCertificationTypeID` INT NOT NULL AUTO_INCREMENT,
  `intRealmID` INT NOT NULL,
  `strCertificationType` VARCHAR(50) NOT NULL,
  `strCertificationName` VARCHAR(50) NOT NULL,
  `tTimeStamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intActive` TINYINT NOT NULL DEFAULT 1,
  intActiveOrder  TINYINT NOT NULL DEFAULT 0,
  `intDisplayOrder` smallint(6) DEFAULT '0',
    strGroupSport varchar(30) default '',
  PRIMARY KEY (`intCertificationTypeID`)
) DEFAULT CHARSET=utf8;
