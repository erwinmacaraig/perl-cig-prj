CREATE TABLE `tblMatrix` (
    intMatrixID int NOT NULL AUTO_INCREMENT,
    intRealmID  INT DEFAULT 0,
/* IF ANY OF THE BELOW CHANGE -- ADJUST tblPersonRegistration*/
    intSubRealmID  INT DEFAULT 0,
    strPersonType VARCHAR(20) DEFAULT '',
    strPersonLevel varchar(10) DEFAULT '', /* pro, amateur */  
    strSport    VARCHAR(20) DEFAULT '',
    intOriginLevel INT DEFAULT 0, /* Self, club, Reg, MA */
    intOriginID INT DEFAULT 0,
    strListOfApprovals VARCHAR(250) DEFAULT '', /* OR A 1-many table ? */
    strRegTypes varchar(100) DEFAULT '', /* NEW, RENEWAL, AMEND, TRANSFER */
    intMinAge INT DEFAULT 0,
    intMaxAge INT DEFAULT 0,

    intIsPaymentRequired TINYINT DEFAULT 0,
    strListOfDocuments VARCHAR(250) DEFAULT '', /* OR A 1-many table ? */
    
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    dtAdded date,
    intAddedUserID INT DEFAULT 0,
    intOriginalMatrixID INT DEFAULT 0,


  PRIMARY KEY (intMatrixID),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intSubRealmID` (`intSubRealmID`),
  KEY `index_intPersonType` (`intStakeholderType`)
) DEFAULT CHARSET=utf8;
