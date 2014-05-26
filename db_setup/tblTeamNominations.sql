DROP TABLE IF EXISTS tblTeamNominations;
CREATE TABLE tblTeamNominations  (
  intTeamNominationID    INT(11) NOT NULL AUTO_INCREMENT,
  intSeasonID            INT(11) NOT NULL,
  intAssocID             INT(11) NOT NULL, 
  intClubID              INT(11) NOT NULL,
  intCompID              INT(11) DEFAULT 0,
  intTeamID              INT(11) DEFAULT 0,
  intNominationCodeID    INT(11) NOT NULL,
  intPrefVenueID         INT(11),
  strPrefStartTime       VARCHAR(100) DEFAULT '',
  strPrefHomeAwayRound1  VARCHAR(100) DEFAULT '',
  intStatus              TINYINT(4) NOT NULL,
  strClubComments        TEXT,
  strCustom1             VARCHAR(100) DEFAULT '',
  dtSubmitted            DATETIME,
  strAcceptRejectReason  VARCHAR(100) DEFAULT '',
  dtAccepted             DATETIME, 
  intRecStatus           TINYINT(4) DEFAULT 0,
  tTimeStamp             TIMESTAMP,
 
  PRIMARY KEY (intTeamNominationID),
  KEY index_intSeasonID (intSeasonID),
  KEY index_intAssocID (intAssocID),
  KEY index_intClubID (intClubID)
);
