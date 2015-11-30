CREATE TABLE `tmpImportedDocuments` (
  `intID` int(11) NOT NULL AUTO_INCREMENT,
    `strType` varchar(30) DEFAULT '',
  `strPersonCode` varchar(30) DEFAULT '',
    `validFrom` date DEFAULT NULL,
  `validTo` date DEFAULT NULL,
    `strUsage` varchar(50) DEFAULT '',
  `originalFilename` varchar(100) DEFAULT '',
    `PRregoImport` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`intID`),
    KEY `index_strType` (`strType`),
  KEY `index_personCode` (`strPersonCode`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8
