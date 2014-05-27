DROP TABLE IF EXISTS `tblDuplChanges`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblDuplChanges` (
  `intDuplChangesID` int(11) NOT NULL AUTO_INCREMENT,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intOldID` int(11) NOT NULL DEFAULT '0',
  `intNewID` int(11) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intISSUE` int(11) DEFAULT '0',
  PRIMARY KEY (`intDuplChangesID`),
  KEY `index_intAssocIDtstamp` (`intAssocID`,`tTimeStamp`),
  KEY `index_intOldID` (`intOldID`),
  KEY `index_intNewID` (`intNewID`),
  KEY `index_intAssocIDtstampNew` (`intAssocID`,`tTimeStamp`,`intNewID`),
  KEY `index_intAssocIDtstampOld` (`intAssocID`,`tTimeStamp`,`intOldID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

