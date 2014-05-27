CREATE TABLE `tblMatrix` (
    intMatrixID int NOT NULL AUTO_INCREMENT,
    intRealmID  INT DEFAULT 0,
    intSubRealmID  INT DEFAULT 0,
    intStakeholderType INT DEFAULT 0,
    intSport    INT DEFAULT 0,
    intOrigin INT DEFAULT 0, /* Self, club, Reg, MA */
    intOriginID INT DEFAULT 0,
    strListOfApprovals VARCHAR(250) DEFAULT '', /* OR A 1-many table ? */
    strRegTypes varchar(100) DEFAULT '', /* NEW, RENEWAL, AMEND, TRANSFER */
    intPlayerType varchar(10) DEFAULT '', /* PRO, AMATUER, GRASSROOTS */
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
  KEY `index_intStakeholderType` (`intStakeholderType`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
#
