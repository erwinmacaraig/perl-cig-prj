DROP TABLE IF EXISTS tblPersonRegistration_XX;
CREATE TABLE tblPersonRegistration_XX (
    intPersonRegistrationID int(11) NOT NULL auto_increment,
    intPersonID int(11) default 0,
    intEntityID int(11) default 0,
    strPersonType varchar(20) default '', /* player, coach, referee */
    strPersonSubType varchar(50) default '', /*?? or ID */
    strPersonLevel varchar(10) DEFAULT '', /* pro, amateur */
    strPersonEntityRole varchar(50) DEFAULT '', /* Referee, Head Coach, Delegate, Other */
    
    strStatus varchar(20) default '', /*Pending, Active,Passive, Transferred */
    strSport varchar(20) default '',
    intCurrent tinyint default 0,
    intOriginLevel TINYINT DEFAULT 0, /* Self, club, Reg, MA */
    intOriginID INT DEFAULT 0, 
    intRegistrationNature int default 0, /*First, Subsequent -- We haev a count ? */

    dtFrom date,
    dtTo date,

    intRealmID  INT DEFAULT 0,
    intSubRealmID  INT DEFAULT 0,
    
    dtAdded datetime,
    dtLastUpdated datetime,
    intIsPaid tinyint default 0,
    intNationalPeriodID INT NOT NULL DEFAULT 0,
    intAgeGroupID  INT NOT NULL DEFAULT 0,
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY  (intPersonRegistrationID),
  KEY index_intPersonID (intPersonID),
  KEY index_intEntityID (intEntityID),
  KEY index_strPersonType (strPersonType),
  KEY index_strStatus (strStatus),
  KEY index_IDs (intEntityID, intPersonID)
) DEFAULT CHARSET=utf8;