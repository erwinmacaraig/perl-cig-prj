DROP TABLE IF EXISTS tblWFRuleDocuments;

CREATE TABLE `tblWFRuleDocuments` (
    `intWFRuleDocumentID` int(11) NOT NULL AUTO_INCREMENT,
    `intWFRuleID` int(11) NOT NULL COMMENT 'The intApprovalEntityID will also approve/verify the document',
    `intDocumentTypeID` int(11) NOT NULL COMMENT 'To be checked against intDocumentTypeID in tblDocuments',
    `intAllowProblemResolutionLevel` int(11) DEFAULT '0',
    `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`intWFRuleDocumentID`),
    KEY `KEY` (`intWFRuleID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1
