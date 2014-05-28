DROP TABLE IF EXISTS tblEntityDocuments;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE tblEntityDocuments(
    intDocumentTypeID INT DEFAULT 0,
    intEntityLevel tinyint default 0, /*Region, Club*/
    intEntityType int default 0, /* Club, School */
    intRequired TINYINT DEFAULT 0, /* 1 = Yes */

  PRIMARY KEY (intDocumentID, intEntityLevel, intEntityType)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

