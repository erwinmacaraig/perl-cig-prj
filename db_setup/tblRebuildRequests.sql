DROP TABLE IF EXISTS tblRebuildRequests;
CREATE TABLE tblRebuildRequests  (
  intRebuildRequestID INT NOT NULL AUTO_INCREMENT,
  intType         TINYINT NOT NULL, /* Defs::Rebuild_Requests */
  intAssocID      INT NOT NULL DEFAULT 0,
  intCompID       INT DEFAULT 0,
  intPoolID       INT DEFAULT 0,
  intTeamID       INT DEFAULT 0,
  intMemberID     INT DEFAULT 0,
  dtAdded         datetime NOT NULL,
  dtCompleted     datetime DEFAULT NULL,
  intStatus       TINYINT NOT NULL DEFAULT 0,
  strRequestedBy  VARCHAR(200),
  PRIMARY KEY (intRebuildRequestID),
  KEY index_CompID (intCompID),
  KEY index_TeamID (intTeamID)
);
