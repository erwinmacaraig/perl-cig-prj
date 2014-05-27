DROP TABLE IF EXISTS `tblProductAttributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblProductAttributes` (
  `intProductAttributeID` int(11) NOT NULL AUTO_INCREMENT,
  `intProductID` int(11) NOT NULL,
  `intAttributeType` int(11) NOT NULL,
  `strAttributeValue` varchar(50) NOT NULL,
  `intRealmID` int(11) DEFAULT '0',
  `intID` int(11) DEFAULT '0',
  `intLevel` int(11) DEFAULT '0',
  PRIMARY KEY (`intProductAttributeID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intIDLevel` (`intID`,`intLevel`),
  KEY `index_intProductID` (`intProductID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

