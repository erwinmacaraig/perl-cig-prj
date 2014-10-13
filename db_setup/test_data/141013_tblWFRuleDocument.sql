

-- intWFRuleID = 1141; RA can view, verify and add document 3, CLUB can view and add document 3
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(1141, 3, 1, 1, 1, 0, NOW());

-- intWFRuleID = 1141; RA can only view document 4, CLUB can view and add document 4 
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(1141, 4, 0, 0, 1, 0, NOW());

-- intWFRuleID = 1096; MA can view, verify and add document 4, CLUB can view and add document 4
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(1096, 4, 1, 1, 1, 0, NOW());

-- intWFRuleID = 1096; MA can view, verify and add document 3, CLUB can view and add document 3
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(1096, 3, 0, 0, 1, 0, NOW());
