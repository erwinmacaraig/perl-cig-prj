CREATE table tblVenue (
    intVenueID  INT NOT NULL AUTO_INCREMENT,
    intEntityID int(11) NOT NULL DEFAULT '0',
    intRealmID int(11) NOT NULL DEFAULT '0',
    intSubRealmID int(11) NOT NULL DEFAULT '0',

    strStatus varchar(20) default '',
    intRealmApproved tinyint default 0,
    intCreatedByEntityID default 0,
    strFIFAID varchar(30) default '',

    strLocalName varchar(150) DEFAULT '',
    strLocalShortName varchar(150) DEFAULT '',
    strLocalFacilityName varchar(150) DEFAULT '',

    strLatinName varchar(150) DEFAULT '',
    strLatinShortName varchar(150) DEFAULT '',
    strLatinFacilityName varchar(150) DEFAULT '',

    dtFrom date,
    dtTo date,

    strISOCountry varchar(10) default '',
    strRegion varchar(50) default '',
    strPostalCode varchar(15) DEFAULT '',
    strTown varchar(100) default '',
    strAddress varchar(200) default '',
    strWebURL varchar(200) default '',
    strEmail varchar(200) default '',
    strPhone varchar(20) DEFAULT '',
    strFax varchar(20) DEFAULT '',
    
    strDiscipline varchar(100) default '', /* list of sports? */
    intCapacity int(11) DEFAULT '0',
    intCoveredSeats int(11) DEFAULT '0',
    intUncoveredSeats int(11) DEFAULT '0',
    intCoveredStandingPlaces int(11) DEFAULT '0',
    intUncoveredStandingPlaces int(11) DEFAULT '0',
    intLightCapacity int(11) DEFAULT '0',
    strGroundNature varchar(30) DEFAULT '', /* Grass, Turf */
    strVenueType varchar(30) DEFAULT '',
  
    
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    strMapRef varchar(20) DEFAULT '',
    intMapNumber int(11) DEFAULT '0',
    dblLat double DEFAULT '0',
    dblLong double DEFAULT '0',
    strDescription text,

PRIMARY KEY (intFacilityID),
  KEY index_intEntityID (intEntityID),
  KEY index_intRealmID (intRealmID),
  KEY index_intSubRealmID (intSubRealmID)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
