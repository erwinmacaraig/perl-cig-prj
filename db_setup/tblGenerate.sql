DROP TABLE IF EXISTS tblGenerate;
CREATE TABLE tblGenerate (
  intGenerateID int(11) NOT NULL AUTO_INCREMENT,
  intRealmID int(11) NOT NULL DEFAULT '0',
  intSubRealmID int(11) NOT NULL DEFAULT '0',
  intEntityID int(11) NOT NULL DEFAULT '0',
  strGenType VARCHAR(30) NOT NULL DEFAULT '',
  intLength int(11) DEFAULT '5',
  intMaxNum int(11) DEFAULT '10000',
  intCurrentNum int(11) NOT NULL DEFAULT '100',
  tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  strFormat VARCHAR(250) NOT NULL DEFAULT '',
  strValues TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (intGenerateID),
  KEY index_type (intRealmID, strGenType)
) DEFAULT CHARSET=utf8;

