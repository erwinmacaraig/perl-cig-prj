DROP TABLE IF EXISTS tblIdentifiers;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE tblIdentifiers (
    intIdentifierID int(11) NOT NULL AUTO_INCREMENT,
    intTableType tinyint default 0, /*Entity, Member*/
    intID INT DEFAULT 0, /*ID within above table */
    strIdentifier varchar(100) default '',
    strIDType varchar(30) default '', /*Define per MA ?? */
    strISOCountry varchar(10) default '',
    dtFrom date,
    dtTo date.
    strDescription varchar(200) default '',

    dtAdded datetime,

    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (intEntityIdentifierID),
  KEY index_EntityIDType (intEntityID, strIDType)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

