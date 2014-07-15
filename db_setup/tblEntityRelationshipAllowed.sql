DROP TABLE IF EXISTS tblEntityRegistrationAllowed;
CREATE TABLE `tblEntityRegistrationAllowed` (
  `intEntityRegistrationAllowedID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) NOT NULL,
  `strPersonType` varchar(20) NOT NULL,
  `strSport` varchar(20) NOT NULL,
  `strPersonLevel` varchar(20) NOT NULL,
  `strRegistrationNature` varchar(20) NOT NULL,
  `strAgeLevel` varchar(20) NOT NULL,
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intEntityRegistrationAllowedID`)
) DEFAULT CHARSET=utf8 COMMENT='This table shows which permuation and combination of players/coaches are available at each Entity';