DROP TABLE IF EXISTS tblDuplChanges;
CREATE TABLE tblDuplChanges(
  intDuplChangesID int NOT NULL auto_increment,
  intAssocID int NOT NULL default '0',
  intOldID int NOT NULL default '0',
  intNewID int NOT NULL default '0',
  tTimeStamp timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (intDuplChangesID),
  KEY index_intAssocIDtstamp (intAssocID, tTimeStamp)
);

