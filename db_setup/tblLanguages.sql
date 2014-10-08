DROP TABLE IF EXISTS tblLanguages;
CREATE TABLE tblLanguages (
  intLanguageID int(11) NOT NULL AUTO_INCREMENT,
  intRealmID INT NOT NULL,
  intSubRealmID INT NOT NULL,
  strName varchar(100) DEFAULT '',
  strNameLocal varchar(100) DEFAULT '',
  strLocale VARCHAR(10) DEFAULT '',
  intNonLatin TINYINT DEFAULT 0,

  PRIMARY KEY (intLanguageID),
  KEY index_intRealmID (intRealmID)
) DEFAULT CHARSET=utf8;

