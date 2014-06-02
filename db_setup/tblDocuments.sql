DROP TABLE IF EXISTS tblDocuments;
CREATE TABLE tblDocuments (
    intDocumentID int NOT NULL AUTO_INCREMENT,
    intDocumentTypeID INT DEFAULT 0,
    intEntityLevel tinyint default 0, /*Person, Entity */
    intEntityID INT DEFAULT 0, /* ID of the Person, Entity*/
    intApprovalStatus TINYINT DEFAULT 0, /* 0 =pending , -1=No, 1 = Yes */
    strDeniedNotes  TEXT default '',
    dtAdded datetime,
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (intDocumentID),
  KEY index_DocumentType(intDocumentID),
  KEY index_Entity(intEntityLevel , intEntityID),
) DEFAULT CHARSET=utf8;

