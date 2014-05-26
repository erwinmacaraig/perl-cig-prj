
## This is the old olr.tblAssocConfig
CREATE TABLE tblAssocCompConfig (
  intAssocConfigID      INT NOT NULL AUTO_INCREMENT,
  intAssocID        INT DEFAULT 0,
  intCompID       INT DEFAULT 0,
  strConfigArea       VARCHAR(50) DEFAULT '',
  strKey          VARCHAR(50) DEFAULT '',
  strValue        VARCHAR(255) DEFAULT '',
  strValue_long       TEXT,
  tTimeStamp        TIMESTAMP,

  PRIMARY KEY (intAssocConfigID),
  KEY index_AssocID (intAssocID),
  KEY index_CompID (intCompID)
);

