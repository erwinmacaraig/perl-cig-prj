DROP TABLE IF EXISTS tblRegistrationRule;
CREATE TABLE `tblRegistrationRule` (
  `intRegistrationRuleID` int(11) NOT NULL AUTO_INCREMENT,
  `strEntityID` int(11) NOT NULL,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) NOT NULL,
  `strPersonType` varchar(20) NOT NULL,
  `strPersonLevel` varchar(20) NOT NULL,
  `strSport` varchar(20) NOT NULL,
  `intRegistrationNature` int(11) NOT NULL,
  `strAgeLevel` varchar(20) NOT NULL,
  `strStatus` int(11) NOT NULL COMMENT '0 - Not available for this Entity, 1 - Available',
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intRegistrationRuleID`)
DEFAULT CHARSET=utf8;