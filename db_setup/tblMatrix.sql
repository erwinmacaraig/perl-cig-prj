CREATE TABLE `tblMatrix` (
    intMatrixID int NOT NULL AUTO_INCREMENT,
    intRealmID  INT DEFAULT 0,
/* IF ANY OF THE BELOW CHANGE -- ADJUST tblPersonRegistration*/
    intSubRealmID  INT DEFAULT 0,
    intPersonType INT DEFAULT 0,
    strPersonLevel varchar(10) DEFAULT '', /* pro, amateur */  
    intSport    INT DEFAULT 0,
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


  PRIMARY KEY (intMatrixID),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intSubRealmID` (`intSubRealmID`),
  KEY `index_intPersonType` (`intStakeholderType`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
#
