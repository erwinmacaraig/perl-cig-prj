DROP TABLE IF EXISTS tblPersonEntity_1;
CREATE TABLE tblPersonEntity_1 (
    intPersonEntityID int(11) NOT NULL auto_increment,
    intPersonID int(11) default 0,
    intEntityID int(11) default 0,
    strPEImportPersonCode varchar(45) default '',
    strPEPersonType varchar(20) default '' COMMENT 'The match official role type, e.g. Player, Coach, Referee',
    strPEPersonLevel varchar(30) DEFAULT '' COMMENT 'The level the person was playing on for the club, i.e. amateur, amateur with contract and professional.',
    strPEPersonEntityRole varchar(50) DEFAULT '' COMMENT 'The team official role type, e.g. Coach or Team Doctor.',
    strPESport varchar(20) default '' COMMENT 'The sport/discipline this registration is valid for, e.g. a football player registration is distinct from a beach soccer player registration. FOOTBALL, FUTSAL, BEACH SOCCER.',
    
    strPEStatus varchar(20) default '' COMMENT 'The status of the registration, i.e.. Pending, Active, Passive, Transferred.',

    dtPEFrom date default '0000-00-00' COMMENT 'The date when the validity of this registration starts, e.g. when a player joins and officially registers for a club.',
    dtPETo date default '0000-00-00' COMMENT 'The date when the validity of the registration ends, e.g. when a player officially leaves a club.',

    intRealmID  INT DEFAULT 0,
    
    dtPEAdded datetime,
    dtPELastUpdated datetime,
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY  (intPersonEntityID),
  KEY index_intPersonID (intPersonID),
  KEY index_intEntityID (intEntityID),
  KEY index_strPEPersonType (strPEPersonType),
  KEY index_strPEStatus (strPEStatus),
  KEY index_IDs (intEntityID, intPersonID)
) DEFAULT CHARSET=utf8;
