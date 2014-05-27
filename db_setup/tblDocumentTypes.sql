DROP TABLE IF EXISTS tblDocumentTypes;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE tblDocumentTypes (
    intDocoID INT DEFAULT 0,
    intUsedBy tinyint default 0, /*Person, Entity, Venue*/
    intRealmID INT DEFAULT 0, /*If for a specific realm */
    intSubRealmID INT DEFAULT 0, /*If for a specific sub realm */
    strDocoName VARCHAR(100) default '',
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    intStatus TINYINT DEFAULT 0, /* 1 = Yes */

  PRIMARY KEY (intDocoID),
  KEY index_UsedBy (intUsedBy),
  KEY index_Realms(intRealmID, intSubRealmID)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

