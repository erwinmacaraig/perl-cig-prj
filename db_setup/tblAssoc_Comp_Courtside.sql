CREATE TABLE tblAssoc_Comp_Courtside (
  intCompID   INTEGER NOT NULL,
  strKey      VARCHAR(100) NOT NULL,
  strValue    VARCHAR(100),
  PRIMARY KEY (intCompID, strKey)
);
