DROP TABLE IF EXISTS tblSystemConfigBlob ;
 
CREATE TABLE `tblSystemConfigBlob` (
  `intSystemConfigID` int(11) NOT NULL DEFAULT '0',
  `strBlob` text NOT NULL,
  PRIMARY KEY (`intSystemConfigID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
