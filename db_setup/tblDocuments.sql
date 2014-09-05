DROP TABLE IF EXISTS tblDocuments;

CREATE TABLE IF NOT EXISTS `tblDocuments` (
  `intDocumentID` int(11) NOT NULL AUTO_INCREMENT,
  `intDocumentTypeID` int(11) DEFAULT NULL,
  `intEntityLevel` tinyint(4) DEFAULT NULL,
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `intPersonID` int(11) NOT NULL DEFAULT '0',
  `intPersonRegistrationID` int(11) NOT NULL DEFAULT '0',
  `intClearanceID` int(11) NOT NULL,
  `strDeniedNotes` text,
  `strApprovalStatus` varchar(30) NOT NULL DEFAULT 'PENDING',
  `intUploadFileID` int(11) NOT NULL,
  `dtAdded` datetime DEFAULT NULL,
  `dtLastUpdated` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intDocumentID`)
) ENGINE=InnoDB;
