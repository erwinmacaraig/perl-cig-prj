DROP TABLE IF EXISTS tblDocuments;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE tblDocuments (
    intDocumentUsedID int(11) NOT NULL AUTO_INCREMENT,
    intDocoID INT DEFAULT 0,
    intRealmID INT DEFAULT 0, /*If for a specific realm */
    intSubRealmID INT DEFAULT 0, /*If for a specific sub realm */
    intUsedByTable tinyint default 0, /*Person, Entity, Venue*/
    intUsedByID INT DEFAULT 0, /* ID of the Person, Entity or Venue */
    intApprovalStatus TINYINT DEFAULT 0, /* 0 =pending , -1=No, 1 = Yes */
    strDeniedNotes 
    dtAdded date,
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (intDocumentID),
  KEY index_DocoID(intDocoID),
  KEY index_UsedByID(intUsedByID, intUsedByTable),
  KEY index_Realms(intRealmID, intSubRealmID)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

