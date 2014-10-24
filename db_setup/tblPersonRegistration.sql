DROP TABLE IF EXISTS tblPersonRegistration_XX;
CREATE TABLE tblPersonRegistration_XX (
    intPersonRegistrationID int(11) NOT NULL auto_increment,
    intPersonID int(11) default 0,
    strImportPersonCode varchar(45) NULL,
    intEntityID int(11) default 0,
    strPersonType varchar(20) default '' COMMENT 'The match official role type, e.g. Player, Coach, Referee',
    strPersonSubType varchar(20) default '', /* NOT USED FOR NOW */
    strPersonLevel varchar(30) DEFAULT '' COMMENT 'The level the person was playing on for the club, i.e. amateur, amateur with contract and professional.',
    strPersonEntityRole varchar(50) DEFAULT '' COMMENT 'The team official role type, e.g. Coach or Team Doctor.',
    
    strStatus varchar(20) default '' COMMENT 'The status of the registration, i.e.. Pending, Active, Passive, Transferred.',
    strPreTransferredStatus varchar(20) default '', /*Pending, Active,Passive, Transferred */
    strSport varchar(20) default '' COMMENT 'The sport/discipline this registration is valid for, e.g. a football player registration is distinct from a beach soccer player registration. FOOTBALL, FUTSAL, BEACH SOCCER.',
    intCurrent tinyint default 0,
    intOriginLevel TINYINT DEFAULT 0, /* Self, club, Reg, MA */
    intOriginID INT DEFAULT 0, 
    intCreatedByUserID INT DEFAULT 0,
    strRegistrationNature VARCHAR(30) default '', /*NEW, REREG, AMEND etc*/
    strAgeLevel VARCHAR(100) default '',

    dtFrom date COMMENT 'The date when the validity of this registration starts, e.g. when a player joins and officially registers for a club.',
    dtTo date COMMENT 'The date when the validity of the registration ends, e.g. when a player officially leaves a club.',

    intRealmID  INT DEFAULT 0,
    intSubRealmID  INT DEFAULT 0,
    
    dtAdded datetime,
    dtLastUpdated datetime,
    intIsPaid tinyint default 0,
    intNationalPeriodID INT NOT NULL DEFAULT 0,
    intAgeGroupID  INT NOT NULL DEFAULT 0,
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    intPaymentRequired TINYINT DEFAULT 0,
    intClearanceID  INT DEFAULT 0,
    strShortNotes VARCHAR(250) NULL DEFAULT NULL COMMENT 'can only be added/edited/viewed by MA level',

  PRIMARY KEY  (intPersonRegistrationID),
  UNIQUE INDEX `strImportPersonCode_UNIQUE` (`strImportPersonCode` ASC),
  KEY index_intPersonID (intPersonID),
  KEY index_intEntityID (intEntityID),
  KEY index_strPersonType (strPersonType),
  KEY index_strStatus (strStatus),
  KEY index_IDs (intEntityID, intPersonID)
) DEFAULT CHARSET=utf8;
