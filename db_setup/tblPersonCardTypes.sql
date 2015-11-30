DROP TABLE IF EXISTS tblPersonCardTypes;
CREATE TABLE tblPersonCardTypes (
    strType VARCHAR(20) DEFAULT '' NOT NULL,
    intPersonCardID int NOT NULL,
  PRIMARY KEY (strType, intPersonCardID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

