DROP TABLE IF EXISTS tblPersonCardPrint;
CREATE TABLE tblPersonCardPrint (
    intPersonCardPrintID INT NOT NULL AUTO_INCREMENT,
    intPersonID INT NOT NULL,
    strType VARCHAR(20) NOT NULL,
    intRegistrationID INT NOT NULL,
    intReprint TINYINT NOT NULL DEFAULT 0,
    intBatchID INT NOT NULL DEFAULT 0,
    intCardID INT NOT NULL DEFAULT 0,
    dtAdded DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    dtPrinted DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',

  PRIMARY KEY (intPersonCardPrintID),
  KEY index_unprinted(dtPrinted, strType),
  KEY index_batch(intBatchID),
  KEY index_card(intCardID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

