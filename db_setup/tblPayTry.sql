DROP TABLE IF EXISTS tblPayTry;
CREATE TABLE tblPayTry  (
    intTryID int(11) NOT NULL auto_increment,
    intRealmID INT default 0,
    intSelfRego TINYINT default 0,
    strPayReference varchar(100) default '',
    intTransLogID INT default 0,
    strLog text,
    dtTry datetime default NULL,
    strContinueAction varchar(50) default '';

    tTimeStamp TIMESTAMP,
  PRIMARY KEY  (intTryID),
  KEY index_realmID (intRealmID),
  KEY index_transLogID(intTransLogID)
) DEFAULT CHARSET=utf8;

