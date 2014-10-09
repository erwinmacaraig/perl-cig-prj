DROP TABLE IF EXISTS `tblCustomFields`;
CREATE TABLE `tblCustomFields` (
  `intCustomFieldsID` int(11) NOT NULL AUTO_INCREMENT,
  `strDBFName` varchar(30) NOT NULL DEFAULT '',
  `strName` varchar(100) NOT NULL DEFAULT '',
  `intLocked` smallint(6) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intRecStatus` tinyint(4) DEFAULT '0',
  `intSubTypeID` int(11) DEFAULT '0',
  PRIMARY KEY (`intCustomFieldsID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `INDEX_intRecStatus` (`intRecStatus`)
) DEFAULT CHARSET=utf8;

