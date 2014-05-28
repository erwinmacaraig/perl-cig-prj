DROP TABLE IF EXISTS tblDocumentTypes;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE tblDocumentTypes (
    intDocumentTypeID INT NOT NULL AUTO_INCREMENT,
    strDocumentName VARCHAR(100) default '',
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    intActive TINYINT default 1,

  PRIMARY KEY (intDocumentTypeID)
) DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

