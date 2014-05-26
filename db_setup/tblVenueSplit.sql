DROP TABLE IF EXISTS tblVenueSplit;
CREATE TABLE tblVenueSplit (
  intVenueSplitID int(11) NOT NULL auto_increment,
  intVenueID      int(11) NOT NULL,
  intAssocID      int(11) NOT NULL DEFAULT 0,
  intPercentage   int(11) NOT NULL,
  intRecStatus    tinyint NOT NULL DEFAULT 0,
  tTimeStamp      timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY (intVenueSplitID),
  KEY index_intVenueID(intVenueID)
);

DROP TABLE IF EXISTS tblVenueSplitParts;
CREATE TABLE tblVenueSplitParts (
  intVenueSplitPartID int(11) NOT NULL auto_increment,
  intVenueSplitID     int(11) NOT NULL,
  strName             varchar(50), 
  tTimeStamp          timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY (intVenueSplitPartID),
  KEY index_intVenueSplitID(intVenueSplitID)
);
