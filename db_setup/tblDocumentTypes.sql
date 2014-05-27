DROP TABLE IF EXISTS tblDocumentTypes;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE tblDocumentTypes (
    intDocumentID INT NOT NULL AUTO_INCREMENT,
    intUsedBy tinyint default 0, /*Person, Entity, Venue*/
    intRealmID INT DEFAULT 0, /*If for a specific realm */
    intSubRealmID INT DEFAULT 0, /*If for a specific sub realm */
    strDocumentCode VARCHAR(100) default '',
    strDocumentName VARCHAR(100) default '',
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    strStatus VARCHAR(20) default '', /* 1 = Yes */

  PRIMARY KEY (intDocumentID),
  KEY index_UsedBy (intUsedBy),
  KEY index_Realms(intRealmID, intSubRealmID)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

