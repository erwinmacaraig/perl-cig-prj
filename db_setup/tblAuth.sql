DROP TABLE IF EXISTS `tblAuth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAuth` (
  `intAuthID` int(11) NOT NULL AUTO_INCREMENT,
  `strUsername` varchar(12) NOT NULL DEFAULT '',
  `strPassword` varchar(12) NOT NULL DEFAULT '',
  `intLevel` int(11) NOT NULL DEFAULT '0',
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intID` int(11) NOT NULL DEFAULT '0',
  `intLogins` int(11) DEFAULT NULL,
  `dtLastlogin` date DEFAULT NULL,
  `dtCreated` date DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intReadOnly` tinyint(4) DEFAULT '0',
  `intRoleID` int(11) DEFAULT '0',
  PRIMARY KEY (`intAuthID`),
  UNIQUE KEY `index_username` (`strUsername`,`intID`,`intLevel`),
  KEY `index_intLevel` (`intLevel`,`strPassword`,`strUsername`),
  KEY `index_dual` (`intLevel`,`intID`)
) ENGINE=MyISAM AUTO_INCREMENT=3667386 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

