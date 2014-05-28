DROP TABLE IF EXISTS tblDocuments;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE tblDocuments (
    intDocumentID int(11) NOT NULL AUTO_INCREMENT,
    intDocumentTypeID INT DEFAULT 0,
    intEntityLevel tinyint default 0, /*Person, Entity, Venue*/
    intEntityID INT DEFAULT 0, /* ID of the Person, Entity or Venue */
    intApprovalStatus TINYINT DEFAULT 0, /* 0 =pending , -1=No, 1 = Yes */
    strDeniedNotes  TEXT default '',
    dtAdded date,
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (intDocumentID),
  KEY index_DocumentType(intDocumentID),
  KEY index_Entity(intEntityLevel , intEntityID),
) DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

