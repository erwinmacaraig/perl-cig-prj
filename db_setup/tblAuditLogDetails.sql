CREATE TABLE tblAuditLogDetails (
  intAuditLogDetailsID int(11) NOT NULL auto_increment,
  intAuditLogID int(11) NOT NULL,
  strField varchar(30) default '',
  strPreviousValue varchar(90) default '',
  PRIMARY KEY  (intAuditLogDetailsID),
  KEY index_intAuditLogID (intAuditLogID)
);

