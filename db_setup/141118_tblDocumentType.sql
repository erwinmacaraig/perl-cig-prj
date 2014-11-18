CREATE TABLE tblDocumentType (
  intDocumentTypeID int(11) NOT NULL AUTO_INCREMENT,
  intRealmID int(11) NOT NULL,
  strDocumentName varchar(100) DEFAULT '',
  tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  intActive tinyint(4) DEFAULT '1',
  strDocumentFor varchar(255) DEFAULT NULL,
  strLockAtLevel varchar(15) NOT NULL DEFAULT '',
  strDescription varchar(255) DEFAULT '',
  PRIMARY KEY (intDocumentTypeID),
  KEY index_realm (intRealmID)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8
