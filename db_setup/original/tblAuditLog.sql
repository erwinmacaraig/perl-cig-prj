
DROP TABLE IF EXISTS tblAuditLog;

CREATE TABLE tblAuditLog (
  intAuditLogID int(11) NOT NULL auto_increment,
  intID int(11) NOT NULL default '0',
  strUsername varchar(30) default '',
  strType varchar(30) default '',
  strSection varchar(30) default '',
  intEntityTypeID int,
  intEntityID int,
  intLoginEntityTypeID int,
  intLoginEntityID int,
  dtUpdated datetime default NULL,
  PRIMARY KEY  (intAuditLogID),
  KEY index_intID (intID),
  KEY index_strUsername (strUsername)
);

