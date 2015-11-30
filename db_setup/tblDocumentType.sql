DROP TABLE IF EXISTS tblDocumentType;
CREATE TABLE tblDocumentType (
    intDocumentTypeID INT NOT NULL AUTO_INCREMENT,
    intRealmID INT NOT NULL,
    strDocumentName VARCHAR(100) default '',
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    intActive TINYINT default 1,
    strLockAtLevel varchar(15) DEFAULT '',
    strActionPending varchar(30) default '',
    intImageCrop TINYINT default 0,
    intEntityImage TINYINT default 0,
  PRIMARY KEY (intDocumentTypeID),
    KEY index_realm(intRealmID)
) DEFAULT CHARSET=utf8;

