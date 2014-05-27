DROP TABLE IF EXISTS tblEntity;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE tblEntity (
  intEntityID int(11) NOT NULL AUTO_INCREMENT,
    intEntityLevel INT DEFAULT 0,
    intRealmID INT DEFAULT 0,
    intEntityType INT DEFAULT 0, /* School, Club */
    intStatus INT DEFAULT 0, /*Approved, pending, inactive, suspended */
    
    strLocalName    varchar(100) default '',
    strLocalShortName varchar(100) default '',
    strLatinName    varchar(100) default '',
    strLatinShortName varchar(100) default '',

    dtFrom date,
    dtTo date,
    strISOCountry varchar(10) default '',
    strRegion varchar(50) default '',
    strPostalCode varchar(15) DEFAULT '',
    strTown varchar((100) default '',
    strAddress varchar(200) default '',
    strWebURL varchar(200) default '',
    strEmail varchar(200) default '',
    strPhone varchar(20) DEFAULT '',
    strFax varchar(20) DEFAULT '',

    strContactTitle varchar(50) DEFAULT NULL,
    strContactEmail varchar(200) DEFAULT NULL,
    strContactPhone varchar(50) DEFAULT NULL,
    dtAdded datetime,

    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`intEntityID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intEntityLevel` (`intEntityLevel`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

