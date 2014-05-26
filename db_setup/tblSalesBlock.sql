DROP TABLE IF EXISTS tblSalesBlock;
CREATE TABLE tblSalesBlock (
  intSalesBlockID int NOT NULL auto_increment,
  strName varchar(150),
  strTitle varchar(50),
	strURL VARCHAR(200),
	intRanking TINYINT DEFAULT 5,
	intType TINYINT DEFAULT 1,


  PRIMARY KEY (intSalesBlockID),
		KEY index_intType(intType)
);
