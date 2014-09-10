DROP TABLE IF EXISTS tblRegoAgeRestrictions;

CREATE TABLE `tblRegoAgeRestrictions` (
  `intRegoAgeRestrictionID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intSubRealmID` int(11) DEFAULT '0',
  `strSport` varchar(20) DEFAULT '',
  `strPersonType` varchar(30) DEFAULT '',
  `strPersonEntityRole` varchar(30) DEFAULT '',
  `strPersonLevel` varchar(30) DEFAULT '',
  `strRestrictionType` varchar(20) DEFAULT '',
  `strAgeLevel` varchar(30) DEFAULT '',
  `intFromAge` int(11) DEFAULT '0',
  `intToAge` int(11) DEFAULT '0',  
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intRegoAgeRestrictionID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intSubRealmID` (`intSubRealmID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Age restriction rules for PERSON REGO';
