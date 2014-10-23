DROP TABLE IF EXISTS `tblEntityIdentifier`;
CREATE TABLE `tblEntityIdentifier` (
  `intIdentifierId` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityID` int(11) NOT NULL,
  `intRealmID` int(11) NOT NULL,
  `intIdentifierTypeID` int(11) NOT NULL,
  `strIdentifier` varchar(100) NOT NULL,
  `strContryIssued` varchar(100) NOT NULL DEFAULT '',
  `dtValidFrom` date DEFAULT NULL,
  `dtValidUntil` date DEFAULT NULL,
  `strDescription` varchar(250) DEFAULT NULL,
  `dtAdded` datetime DEFAULT NULL,
  `dtLastUpdated` datetime DEFAULT NULL,
  `tTimestamp` varchar(45) DEFAULT 'CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
  `intStatus` int(11) DEFAULT '1',
  PRIMARY KEY (`intIdentifierId`)
) DEFAULT CHARSET=utf8;
