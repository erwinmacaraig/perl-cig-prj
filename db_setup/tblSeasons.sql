CREATE TABLE tblSeasons (
  intSeasonID INT NOT NULL AUTO_INCREMENT,
  strSeasonName VARCHAR(100),
  strSport VARCHAR(20) DEFAULT ''
  intRealmID INT,
  intSubRealmID INT,
  dtFrom DATE,
  dtTo DATE,
  PRIMARY KEY (intSeasonID),
  KEY index_intRealm(intRealmID, intSubRealmID, strSport)
)
