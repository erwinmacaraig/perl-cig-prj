DROP TABLE IF EXISTS tblWFRuleDocuments;

CREATE TABLE `tblWFRuleDocuments` (
    `intWFRuleDocumentID` int(11) NOT NULL AUTO_INCREMENT,
    `intWFRuleID` int(11) NOT NULL COMMENT 'The intApprovalEntityID will also approve/verify the document',
    `intDocumentTypeID` int(11) NOT NULL COMMENT 'To be checked against intDocumentTypeID in tblDocuments',
    `intAllowApprovalEntityAdd` int(11) NOT NULL COMMENT 'Allow Approval Entity to add document',
    `intAllowApprovalEntityVerify` int(11) NOT NULL COMMENT 'Allow Approval Entity to verify document',
    `intAllowProblemResolutionEntityAdd` int(11) NOT NULL COMMENT 'Allow Problem Resolution Entity to add document',
    `intAllowProblemResolutionEntityVerify` int(11) NOT NULL COMMENT 'Allow Problem Resolution Entity to verify document',
    `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`intWFRuleDocumentID`),
    KEY `KEY` (`intWFRuleID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
