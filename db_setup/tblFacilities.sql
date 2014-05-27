CREATE table tblFacilities (
    intFacilityID  INT NOT NULL AUTO_INCREMENT,
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `strName` varchar(150) DEFAULT NULL,
  `intRecStatus` tinyint(4) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strAbbrev` varchar(50) DEFAULT '',
  `intTypeID` tinyint(4) DEFAULT '0',
  `strAddress1` varchar(200) DEFAULT '',
  `strAddress2` varchar(200) DEFAULT '',
  `strSuburb` varchar(100) DEFAULT '',
  `strState` varchar(100) DEFAULT '',
  `strPostalCode` varchar(20) DEFAULT '',
  `strCountry` varchar(100) DEFAULT '',
  `strPhone` varchar(50) DEFAULT '',
  `strPhone2` varchar(50) DEFAULT '',
  `strFax` varchar(50) DEFAULT '',
  `strMapRef` varchar(20) DEFAULT '',
  `intMapNumber` int(11) DEFAULT '0',
  `dblLat` double DEFAULT '0',
  `dblLong` double DEFAULT '0',
  `strLGA` varchar(250) DEFAULT NULL,
  `strXCoord` varchar(25) DEFAULT '',
  `strYCoord` varchar(25) DEFAULT '',
  `strtFIFACountryCode` varchar(10) DEFAULT '',
  `strAlias` varchar(50) DEFAULT '',
  `strNativeName` varchar(100) DEFAULT '',
  `strNativeAlias` varchar(50) DEFAULT '',
  `strDescription` text,
  `intCapacity` int(11) DEFAULT '0',
  `intCoveredSeats` int(11) DEFAULT '0',
  `intUncoveredSeats` int(11) DEFAULT '0',
  `intCoveredStandingPlaces` int(11) DEFAULT '0',
  `intUncoveredStandingPlaces` int(11) DEFAULT '0',
  `intLightCapacity` int(11) DEFAULT '0',
  `strGround` varchar(30) DEFAULT '',
  `strVenueType` varchar(30) DEFAULT '',
  `intCourtsideVenueID` int(11) DEFAULT '0',
PRIMARY KEY (intFacilityID),
  KEY `index_intEntityID` (`intEntityID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intSubRealmID` (`intSubRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=50148 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
