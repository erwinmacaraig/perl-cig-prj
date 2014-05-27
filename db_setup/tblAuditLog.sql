DROP TABLE IF EXISTS `tblAuditLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAuditLog` (
  `intAuditLogID` int(11) NOT NULL AUTO_INCREMENT,
  `intID` int(11) NOT NULL DEFAULT '0',
  `strUsername` varchar(30) DEFAULT '',
  `strType` varchar(30) DEFAULT '',
  `strSection` varchar(30) DEFAULT '',
  `intEntityTypeID` int(11) DEFAULT NULL,
  `intEntityID` int(11) DEFAULT NULL,
  `intLoginEntityTypeID` int(11) DEFAULT NULL,
  `intLoginEntityID` int(11) DEFAULT NULL,
  `dtUpdated` datetime DEFAULT NULL,
  `intPassportID` int(11) NOT NULL DEFAULT '0',
  `intItemID` int(11) DEFAULT '0',
  PRIMARY KEY (`intAuditLogID`),
  KEY `index_intID` (`intID`),
  KEY `index_strUsername` (`strUsername`),
  KEY `index_AuditLog` (`intEntityTypeID`,`intEntityID`),
  KEY `index_passportID` (`intPassportID`)
) ENGINE=MyISAM AUTO_INCREMENT=17785308 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
