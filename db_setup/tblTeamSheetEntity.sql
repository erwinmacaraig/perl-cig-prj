CREATE TABLE tblTeamSheetEntity (
	intTeamSheetEntityID int(11) NOT NULL AUTO_INCREMENT,
  intTeamSheetID int(11) DEFAULT 0 NOT NULL,
  intRealmID int(11) DEFAULT 0 NOT NULL,
  intSubRealmID int(11) DEFAULT 0 NOT NULL,
	intAssocID int(11) DEFAULT 0 NOT NULL,
	intCompID int(11) DEFAULT 0 NOT NULL,
  intMinLevel int(11) DEFAULT 0 NOT NULL,
  intMaxLevel int(11) DEFAULT 0 NOT NULL,
  PRIMARY KEY (intTeamSheetEntityID),
  UNIQUE KEY index_ids (intTeamSheetID,intRealmID,intSubRealmID,intAssocID,intCompID)
) 
