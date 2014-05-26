DROP TABLE IF EXISTS tblSalesBlockEntity;
CREATE TABLE tblSalesBlockEntity (
  intSalesBlockEntityID INT NOT NULL  auto_increment,
  intSalesBlockID int NOT NULL,
	intRealmID INT NOT NULL DEFAULT 0,
	intSubRealmID INT NOT NULL DEFAULT 0,
	intAssocs TINYINT NOT NULL DEFAULT 0,
	intClubs TINYINT NOT NULL DEFAULT 0,
	intOther TINYINT NOT NULL DEFAULT 0,
	strCountry VARCHAR(200) DEFAULT '',
	strState VARCHAR(200) DEFAULT '',

  PRIMARY KEY (intSalesBlockEntityID),
  KEY index_intSalesBlockID (intSalesBlockID),
  KEY index_intRealmID (intRealmID)
);
