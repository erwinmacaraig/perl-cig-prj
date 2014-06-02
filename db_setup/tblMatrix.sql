CREATE TABLE `tblMatrix` (
    intMatrixID int NOT NULL AUTO_INCREMENT,
    intRealmID  INT DEFAULT 0,
    intSubRealmID  INT DEFAULT 0,
    intEntityLevel TINYINT DEFAULT 0, /* club/venue/person */
    strEntityType VARCHAR(30) DEFAULT '', /* School/club /Player/COACH*/
/* IF ANY OF THE BELOW CHANGE -- ADJUST tblPersonRegistration*/
    strPersonLevel varchar(10) DEFAULT '', /* pro, amateur */  
    strSport    VARCHAR(20) DEFAULT '',
    intOriginLevel INT DEFAULT 0, /* Self, club, Reg, MA */
    intOriginID INT DEFAULT 0,
    strRegTypes varchar(100) DEFAULT '', /* NEW, RENEWAL, AMEND, TRANSFER */
    intMinAge INT DEFAULT 0,
    intMaxAge INT DEFAULT 0,
    dtAgeAsDate DATE,
    strListOfApprovals VARCHAR(250) DEFAULT '', /* OR A 1-many table ? */
    intIsPaymentRequired TINYINT DEFAULT 0,
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    intProblemResolutionLevel INT NOT NULL DEFAULT 3,

    dtAdded date,

  PRIMARY KEY (intMatrixID),
  KEY `index_intRealmID` (`intRealmID`, intSubRealmID),
  KEY `index_intPersonType` (`strPersonType`)
) DEFAULT CHARSET=utf8;
