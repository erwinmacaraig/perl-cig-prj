CREATE TABLE `tblMatrixProducts` (
    intMatrixID int DEFAULT 0,
    intProductID INT DEFAULT 0,
    intAllowDuplicates TINYINT DEFAULT 0,
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,


  PRIMARY KEY (intMatrixID, intProductID),
  KEY `index_intProductID` (`intProductID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
#
