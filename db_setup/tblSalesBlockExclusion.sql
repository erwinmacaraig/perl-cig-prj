DROP TABLE IF EXISTS tblSalesBlockExclusion;
CREATE TABLE tblSalesBlockExclusion (
  intSalesBlockExclusionID INT NOT NULL  auto_increment,
  intSalesBlockID int NOT NULL,
	intEntityTypeID INT NOT NULL,
	intEntityID INT NOT NULL,

  PRIMARY KEY (intSalesBlockExclusionID),
  KEY index_intSalesBlockID (intSalesBlockID),
  KEY index_entity (intEntityTypeID, intEntityID)
);
