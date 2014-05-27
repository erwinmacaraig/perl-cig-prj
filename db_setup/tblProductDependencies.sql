DROP TABLE IF EXISTS `tblProductDependencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblProductDependencies` (
  `intProductDependencyID` int(11) NOT NULL AUTO_INCREMENT,
  `intProductID` int(11) NOT NULL,
  `intDependentProductID` int(11) NOT NULL,
  `intRealmID` int(11) DEFAULT '0',
  `intID` int(11) DEFAULT '0',
  `intLevel` int(11) DEFAULT '0',
  PRIMARY KEY (`intProductDependencyID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intIDLevel` (`intID`,`intLevel`),
  KEY `index_intProductID` (`intProductID`)
) ENGINE=MyISAM AUTO_INCREMENT=15302 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
