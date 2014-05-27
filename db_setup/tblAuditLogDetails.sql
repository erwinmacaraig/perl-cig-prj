DROP TABLE IF EXISTS `tblAuditLogDetails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAuditLogDetails` (
  `intAuditLogDetailsID` int(11) NOT NULL AUTO_INCREMENT,
  `intAuditLogID` int(11) NOT NULL,
  `strField` varchar(30) DEFAULT '',
  `strPreviousValue` varchar(90) DEFAULT '',
  PRIMARY KEY (`intAuditLogDetailsID`),
  KEY `index_intAuditLogID` (`intAuditLogID`)
) ENGINE=MyISAM AUTO_INCREMENT=517 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
