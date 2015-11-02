DROP TABLE IF EXISTS tblPersonCardBatch;
CREATE TABLE tblPersonCardBatch (
    intPersonCardBatchID INT NOT NULL AUTO_INCREMENT,
    intEntityTypeID INT NOT NULL,
    intEntityID INT NOT NULL,
    intCardID INT NOT NULL,
    dtAdded DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    intStatus TINYINT DEFAULT 0, /* 0 = available, 1 = complete, 2 = cancelled */

  PRIMARY KEY (intPersonCardBatchID),
  KEY index_entity(intEntityTypeID, intEntityID, intStatus)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

