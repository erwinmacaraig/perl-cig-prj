DROP TABLE IF EXISTS tblEntity;
CREATE TABLE tblEntity (
  intEntityID int(11) NOT NULL AUTO_INCREMENT,
    intEntityLevel INT DEFAULT 0,
    intRealmID INT DEFAULT 0,
    intEntityType INT DEFAULT 0, /* School, Club */
    strStatus VARCHAR(20) default '', /*Approved, pending, inactive, suspended */
    intRealmApproved tinyint default 0,
    intCreatedByEntityID default 0,
    strFIFAID varchar(30) default '',
    
    strLocalName    varchar(100) default '',
    strLocalShortName varchar(100) default '',
    strLatinName    varchar(100) default '',
    strLatinShortName varchar(100) default '',

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

    strContactTitle varchar(50) DEFAULT NULL,
    strContactEmail varchar(200) DEFAULT NULL,
    strContactPhone varchar(50) DEFAULT NULL,
    dtAdded datetime,

    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`intEntityID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intEntityLevel` (`intEntityLevel`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

