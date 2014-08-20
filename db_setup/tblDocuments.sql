DROP TABLE IF EXISTS tblDocuments;

CREATE TABLE IF NOT EXISTS tblDocuments (
  intDocumentID INT(11) NOT NULL AUTO_INCREMENT,
  intDocumentTypeID INT(11) NULL,
  intEntityLevel TINYINT(4) NULL,
  intEntityID INT(11) NOT NULL DEFAULT 0,
  intPersonID INT(11) NOT NULL DEFAULT 0,
  intPersonRegistrationID INT(11) NOT NULL DEFAULT 0,
  intClearanceID INT(11) NOT NULL,
  strDeniedNotes TEXT NULL,
  strApprovalStatus VARCHAR(30) NOT NULL DEFAULT 'PENDING',
  intUploadFileID INT(11) NOT NULL,
  PRIMARY KEY (intDocumentID)
)ENGINE = InnoDB;
